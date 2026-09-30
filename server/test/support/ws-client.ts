import { WebSocket } from 'ws';

export interface Message {
  event: string;
  data: unknown;
}

interface Waiter {
  event: string;
  accept: (data: never) => boolean;
  resolve: (data: unknown) => void;
}

/** A WebSocket test client: sends `{event, data}` and awaits server events in order. */
export class WsClient {
  private readonly inbox: Message[] = [];
  private readonly waiters: Waiter[] = [];
  readonly closed: Promise<{ code: number; reason: string }>;

  private constructor(private readonly socket: WebSocket) {
    socket.on('message', (raw: Buffer) => {
      const message = JSON.parse(raw.toString()) as Message;
      const index = this.waiters.findIndex(
        (w) => w.event === message.event && w.accept(message.data as never),
      );
      const waiter = this.waiters[index];
      if (waiter) {
        this.waiters.splice(index, 1);
        waiter.resolve(message.data);
      } else {
        this.inbox.push(message);
      }
    });
    this.closed = new Promise((resolve) => {
      socket.on('close', (code, reason) => {
        resolve({ code, reason: reason.toString() });
      });
    });
  }

  /** Opens `ws://…/ws?token=…`; resolves once connected. */
  static connect(url: string, token?: string): Promise<WsClient> {
    const socket = new WebSocket(token === undefined ? url : `${url}?token=${token}`);
    const client = new WsClient(socket);
    return new Promise((resolve, reject) => {
      socket.once('open', () => {
        resolve(client);
      });
      socket.once('error', reject);
    });
  }

  send(event: string, data: unknown = {}): void {
    this.socket.send(JSON.stringify({ event, data }));
  }

  sendRaw(frame: string): void {
    this.socket.send(frame);
  }

  /** The next [event] (matching [accept]), already received or to come. */
  next<T>(event: string, accept: (data: T) => boolean = () => true, timeoutMs = 5000): Promise<T> {
    const index = this.inbox.findIndex((m) => m.event === event && accept(m.data as T));
    const found = this.inbox[index];
    if (found) {
      this.inbox.splice(index, 1);
      return Promise.resolve(found.data as T);
    }
    return new Promise<T>((resolve, reject) => {
      const waiter: Waiter = {
        event,
        accept: accept,
        resolve: (data) => {
          clearTimeout(timer);
          resolve(data as T);
        },
      };
      const timer = setTimeout(() => {
        this.waiters.splice(this.waiters.indexOf(waiter), 1);
        const pending = this.inbox.map((m) => m.event).join(', ') || 'none';
        reject(new Error(`No "${event}" within ${timeoutMs} ms (unread: ${pending})`));
      }, timeoutMs);
      this.waiters.push(waiter);
    });
  }

  /** Sends [event] and awaits the `error` it causes. */
  async expectError(
    event: string,
    data: unknown,
  ): Promise<{ code: string; message: string; event: string | null }> {
    this.send(event, data);
    return this.next('error');
  }

  /** Forgets the events received so far. */
  clear(): void {
    this.inbox.length = 0;
  }

  /** Events received and not awaited yet. */
  unread(): Message[] {
    return [...this.inbox];
  }

  async close(): Promise<void> {
    if (this.socket.readyState === WebSocket.CLOSED) return;
    this.socket.close();
    await this.closed;
  }
}
