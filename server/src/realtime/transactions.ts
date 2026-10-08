import { Inject, Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, EntityManager, QueryFailedError } from 'typeorm';
import { SerialQueue } from '../common/serial-queue';
import { AppConfig, appConfig } from '../config/app.config';
import { BusMessage, RealtimeBus } from './realtime-bus';

/**
 * A database transaction holding the lock of one or more keys (a room, the
 * ratings, the tournaments). Its messages are sent when it commits.
 */
export class Tx {
  readonly messages: BusMessage[] = [];

  constructor(
    readonly manager: EntityManager,
    private readonly postgres: boolean,
  ) {}

  /**
   * Waits for every other transaction holding [key], on any instance, then
   * holds it until this one ends. Take keys in this order: room, ratings,
   * tournaments.
   */
  async lock(key: string): Promise<void> {
    if (!this.postgres) return; // sql.js: one process, transactions already run one by one.
    await this.manager.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [key]);
  }

  /** Takes [key] only if nobody holds it. */
  async tryLock(key: string): Promise<boolean> {
    if (!this.postgres) return true;
    const rows: { locked: boolean }[] = await this.manager.query(
      'SELECT pg_try_advisory_xact_lock(hashtextextended($1, 0)) AS locked',
      [key],
    );
    return rows[0]?.locked === true;
  }

  publish(message: BusMessage): void {
    this.messages.push(message);
  }
}

/** Deadlock or serialization failure: the transaction can simply run again. */
function isRetryable(error: unknown): boolean {
  if (!(error instanceof QueryFailedError)) return false;
  const code = (error.driverError as { code?: unknown } | undefined)?.code;
  return code === '40P01' || code === '40001';
}

/**
 * Runs the changes of the shared state (rooms, games, ratings,
 * tournaments) one at a time per key, across every instance of the server:
 * each runs in a transaction that first takes the PostgreSQL advisory lock
 * of its key. Within an instance, tasks of the same key also queue in
 * memory, so they do not hold pool connections while waiting.
 *
 * Never call [run] from inside a task: take other keys with `tx.lock`.
 */
@Injectable()
export class TransactionRunner {
  private readonly postgres: boolean;
  private readonly queues = new Map<string, { queue: SerialQueue; pending: number }>();

  constructor(
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly bus: RealtimeBus,
    @Inject(appConfig.KEY) settings: AppConfig,
  ) {
    this.postgres = settings.database.type === 'postgres';
  }

  run<T>(key: string, task: (tx: Tx) => Promise<T>): Promise<T> {
    // sql.js has a single connection: its transactions must not overlap.
    return this.queued(this.postgres ? key : '*', () => this.attempt(key, task));
  }

  private async attempt<T>(key: string, task: (tx: Tx) => Promise<T>): Promise<T> {
    for (let attempt = 1; ; attempt++) {
      let messages: BusMessage[] = [];
      try {
        const result = await this.dataSource.transaction(async (manager) => {
          const tx = new Tx(manager, this.postgres);
          messages = tx.messages;
          await tx.lock(key);
          const value = await task(tx);
          await this.bus.publishInTransaction(manager, messages);
          return value;
        });
        this.bus.afterCommit(messages);
        return result;
      } catch (error) {
        if (attempt < 3 && isRetryable(error)) continue;
        throw error;
      }
    }
  }

  private queued<T>(key: string, task: () => Promise<T>): Promise<T> {
    let entry = this.queues.get(key);
    if (!entry) {
      entry = { queue: new SerialQueue(), pending: 0 };
      this.queues.set(key, entry);
    }
    const current = entry;
    current.pending++;
    return current.queue.run(task).finally(() => {
      if (--current.pending === 0) this.queues.delete(key);
    });
  }
}
