/**
 * Runs async tasks one after the other, in submission order.
 *
 * Used by `TransactionRunner` so that, within one instance, the changes of
 * the same key wait in memory rather than on a database lock.
 */
export class SerialQueue {
  private tail: Promise<unknown> = Promise.resolve();

  run<T>(task: () => Promise<T> | T): Promise<T> {
    const result = this.tail.then(task);
    this.tail = result.catch(() => undefined);
    return result;
  }
}
