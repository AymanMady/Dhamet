import { BeforeApplicationShutdown, Injectable, Logger } from '@nestjs/common';
import { RoomsService } from './rooms.service';

/** How often an instance with connections settles the overdue rooms. */
const SWEEP_INTERVAL_MS = 30_000;

/** Margin after a deadline, so that it has surely passed when the room is settled. */
const MARGIN_MS = 20;

/**
 * The timers of this instance. When a room has a deadline (a forfeit, a
 * clock, a notice, its closing), every instance holding a connection of one
 * of its members settles the room at that time: at least one of them is
 * running, since a connection keeps its instance alive. Settling is
 * idempotent, so several instances doing it is harmless.
 *
 * While it has connections, the instance also sweeps the overdue rooms
 * regularly, in case a deadline was missed.
 */
@Injectable()
export class RoomDeadlines implements BeforeApplicationShutdown {
  private readonly logger = new Logger(RoomDeadlines.name);
  private readonly timers = new Map<string, { at: number; timer: NodeJS.Timeout }>();
  private readonly running = new Set<Promise<unknown>>();
  private sweeper: NodeJS.Timeout | null = null;
  private stopped = false;

  constructor(private readonly rooms: RoomsService) {}

  /** Settles room [code] at [at] (milliseconds since the epoch). */
  watch(code: string, at: number): void {
    if (this.stopped) return;
    const current = this.timers.get(code);
    // An earlier timer settles the room, which then announces its next deadline.
    if (current && current.at <= at) return;
    if (current) clearTimeout(current.timer);
    const timer = setTimeout(
      () => {
        this.timers.delete(code);
        this.track(this.rooms.settle(code), `Could not settle room ${code}`);
      },
      Math.max(0, at - Date.now()) + MARGIN_MS,
    );
    timer.unref();
    this.timers.set(code, { at, timer });
  }

  /** Sweeps regularly while this instance has connections. */
  setSweeping(sweeping: boolean): void {
    if (sweeping && !this.sweeper && !this.stopped) {
      this.sweeper = setInterval(() => {
        this.track(this.rooms.sweep(), 'Sweep failed');
      }, SWEEP_INTERVAL_MS);
      this.sweeper.unref();
    } else if (!sweeping && this.sweeper) {
      clearInterval(this.sweeper);
      this.sweeper = null;
    }
  }

  /** The instance stops: no new timer, and the settling under way ends first. */
  async beforeApplicationShutdown(): Promise<void> {
    this.stopped = true;
    for (const { timer } of this.timers.values()) clearTimeout(timer);
    this.timers.clear();
    this.setSweeping(false);
    await Promise.allSettled(this.running);
  }

  private track(task: Promise<unknown>, failure: string): void {
    const running = task.catch((error: unknown) => {
      this.logger.error(failure, error);
    });
    this.running.add(running);
    void running.finally(() => this.running.delete(running));
  }
}
