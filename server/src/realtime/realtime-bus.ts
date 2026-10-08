import { Logger } from '@nestjs/common';
import { Client, ClientConfig } from 'pg';
import { EntityManager } from 'typeorm';

/** An event for some users, sent to each of their connections, on every instance. */
export interface Delivery {
  to: string[];
  event: string;
  data: unknown;
}

/**
 * What one instance tells the others. The server may run as several
 * instances (Vercel starts as many as the traffic needs): a player's
 * WebSocket is held by one of them, and any of them may handle the moves
 * of the other player.
 */
export interface BusMessage {
  deliveries?: Delivery[];
  /** Users whose connections close as unauthenticated (deleted account). */
  disconnect?: string[];
  /**
   * The next deadline of a room (forfeit, clock, notice, closing): the
   * instances holding a connection of one of its [members] settle the room
   * then.
   */
  watch?: { code: string; at: number; members: string[] };
}

export type BusHandler = (message: BusMessage) => void;

/**
 * Carries [BusMessage]s between instances. Messages of a transaction are
 * only sent if it commits, in commit order.
 */
export abstract class RealtimeBus {
  private readonly handlers: BusHandler[] = [];
  private readonly resumeHandlers: (() => void)[] = [];

  onMessage(handler: BusHandler): void {
    this.handlers.push(handler);
  }

  /**
   * Called when listening resumes after an interruption, during which
   * messages may have been missed.
   */
  onResume(handler: () => void): void {
    this.resumeHandlers.push(handler);
  }

  /** Called inside the transaction, just before it commits. */
  abstract publishInTransaction(manager: EntityManager, messages: BusMessage[]): Promise<void>;

  /** Called once the transaction has committed. */
  abstract afterCommit(messages: BusMessage[]): void;

  /** Publishes at once, outside any transaction, through [manager]. */
  abstract publish(manager: EntityManager, message: BusMessage): Promise<void>;

  /**
   * Whether this instance has connections to deliver to. Without any, it
   * does not need to hear the others.
   */
  abstract setListening(listening: boolean): void;

  /**
   * Resolves once this instance hears the others, so that the events of a
   * request reach its own connections too.
   */
  abstract ready(): Promise<void>;

  abstract close(): Promise<void>;

  protected deliver(message: BusMessage): void {
    for (const handler of this.handlers) handler(message);
  }

  protected resumed(): void {
    for (const handler of this.resumeHandlers) handler();
  }
}

/** A single process: messages go straight to its own connections. */
export class LocalRealtimeBus extends RealtimeBus {
  publishInTransaction(): Promise<void> {
    return Promise.resolve();
  }

  afterCommit(messages: BusMessage[]): void {
    for (const message of messages) this.deliver(message);
  }

  publish(_manager: EntityManager, message: BusMessage): Promise<void> {
    this.deliver(message);
    return Promise.resolve();
  }

  setListening(): void {
    // Always delivered.
  }

  ready(): Promise<void> {
    return Promise.resolve();
  }

  close(): Promise<void> {
    return Promise.resolve();
  }
}

export const BUS_CHANNEL = 'dhamet_realtime';

/** PostgreSQL refuses NOTIFY payloads of 8000 bytes or more. */
const MAX_PAYLOAD_BYTES = 7900;

/** Splits [message] into payloads small enough for NOTIFY. */
export function busPayloads(message: BusMessage): string[] {
  const whole = JSON.stringify(message);
  if (Buffer.byteLength(whole) <= MAX_PAYLOAD_BYTES) return [whole];
  const parts: BusMessage[] = [
    ...(message.deliveries ?? []).map((delivery) => ({ deliveries: [delivery] })),
    ...(message.disconnect ? [{ disconnect: message.disconnect }] : []),
    ...(message.watch ? [{ watch: message.watch }] : []),
  ];
  return parts.map((part) => {
    const payload = JSON.stringify(part);
    if (Buffer.byteLength(payload) > MAX_PAYLOAD_BYTES) {
      throw new Error(`Realtime message too large for NOTIFY: ${payload.slice(0, 120)}…`);
    }
    return payload;
  });
}

/**
 * PostgreSQL LISTEN/NOTIFY: a transaction sends its messages with
 * `pg_notify`, so they leave at commit, in commit order, and never for a
 * rolled-back change. Each instance with connections listens on a direct
 * connection (a transaction pooler cannot LISTEN).
 */
export class PostgresRealtimeBus extends RealtimeBus {
  private readonly logger = new Logger('RealtimeBus');
  private client: Client | null = null;
  private connecting: Promise<void> | null = null;
  private listening = false;
  private retryTimer: NodeJS.Timeout | null = null;
  private idleTimer: NodeJS.Timeout | null = null;
  private retryDelayMs = 500;
  private closed = false;
  /** Whether a listening connection was lost since the last one started. */
  private interrupted = false;

  constructor(
    private readonly connection: ClientConfig,
    /** Stops listening after this long without connections. */
    private readonly idleMs = 60_000,
  ) {
    super();
  }

  async publishInTransaction(manager: EntityManager, messages: BusMessage[]): Promise<void> {
    for (const message of messages) {
      for (const payload of busPayloads(message)) {
        await manager.query('SELECT pg_notify($1, $2)', [BUS_CHANNEL, payload]);
      }
    }
  }

  afterCommit(): void {
    // Delivered by LISTEN, to this instance as to the others.
  }

  publish(manager: EntityManager, message: BusMessage): Promise<void> {
    return this.publishInTransaction(manager, [message]);
  }

  setListening(listening: boolean): void {
    if (this.closed) return;
    this.listening = listening;
    if (listening) {
      if (this.idleTimer) clearTimeout(this.idleTimer);
      this.idleTimer = null;
      void this.ensureConnected();
    } else if (!this.idleTimer) {
      this.idleTimer = setTimeout(() => {
        this.idleTimer = null;
        if (!this.listening) void this.disconnect();
      }, this.idleMs);
      this.idleTimer.unref();
    }
  }

  async ready(): Promise<void> {
    if (this.client || this.closed) return;
    this.setListening(true);
    await this.ensureConnected();
  }

  async close(): Promise<void> {
    this.closed = true;
    this.listening = false;
    if (this.retryTimer) clearTimeout(this.retryTimer);
    if (this.idleTimer) clearTimeout(this.idleTimer);
    await this.disconnect();
  }

  private ensureConnected(): Promise<void> {
    if (this.client) return Promise.resolve();
    this.connecting ??= this.connect().finally(() => {
      this.connecting = null;
    });
    return this.connecting;
  }

  private async connect(): Promise<void> {
    const client = this.newClient();
    client.on('notification', (notification) => {
      if (notification.channel !== BUS_CHANNEL || !notification.payload) return;
      try {
        this.deliver(JSON.parse(notification.payload) as BusMessage);
      } catch (error) {
        this.logger.error('Unreadable realtime message', error);
      }
    });
    client.on('error', (error) => {
      this.logger.warn(`Realtime listener lost: ${error.message}`);
      this.dropped(client);
    });
    client.on('end', () => {
      this.dropped(client);
    });
    try {
      await client.connect();
      await client.query(`LISTEN ${BUS_CHANNEL}`);
    } catch (error) {
      this.logger.warn(`Realtime listener unavailable: ${String(error)}`);
      client.removeAllListeners('end');
      await client.end().catch(() => undefined);
      this.scheduleRetry();
      return;
    }
    if (this.closed || !this.listening) {
      client.removeAllListeners('end');
      await client.end().catch(() => undefined);
      return;
    }
    this.client = client;
    this.retryDelayMs = 500;
    if (this.interrupted) {
      this.interrupted = false;
      this.resumed();
    }
  }

  private dropped(client: Client): void {
    if (this.client !== client) return;
    this.client = null;
    this.interrupted = true;
    client.removeAllListeners();
    client.end().catch(() => undefined);
    this.scheduleRetry();
  }

  private scheduleRetry(): void {
    if (this.closed || !this.listening || this.retryTimer) return;
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null;
      void this.ensureConnected();
    }, this.retryDelayMs);
    this.retryTimer.unref();
    this.retryDelayMs = Math.min(this.retryDelayMs * 2, 10_000);
  }

  private async disconnect(): Promise<void> {
    await this.connecting?.catch(() => undefined);
    const client = this.client;
    this.client = null;
    if (!client) return;
    client.removeAllListeners();
    await client.end().catch(() => undefined);
  }

  private newClient(): Client {
    return new Client(this.connection);
  }
}
