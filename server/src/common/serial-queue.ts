/**
 * Runs async tasks one after the other, in submission order.
 *
 * The server is a single process: queuing the updates of one room, or of
 * the ratings, keeps them consistent without database locks.
 */
export class SerialQueue {
  private tail: Promise<unknown> = Promise.resolve();

  run<T>(task: () => Promise<T> | T): Promise<T> {
    const result = this.tail.then(task);
    this.tail = result.catch(() => undefined);
    return result;
  }
}
