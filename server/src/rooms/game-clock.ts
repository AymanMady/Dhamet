import { Color, opponentOf } from '../engine/engine.types';
import { TimeControl } from './time-control';

export type Clocks = Record<Color, number>;

/**
 * Server-side chess clock (times in milliseconds, [now] from `Date.now()`).
 * Only the side to move loses time; a move adds the increment to the mover.
 */
export class GameClock {
  private readonly remaining: Clocks;
  private readonly incrementMs: number;
  private toMove: Color;
  private turnStartedAt: number;
  private stoppedAt: number | null = null;

  constructor(timeControl: TimeControl, firstToMove: Color, now: number) {
    const initial = timeControl.initialSeconds * 1000;
    this.remaining = { white: initial, black: initial };
    this.incrementMs = timeControl.incrementSeconds * 1000;
    this.toMove = firstToMove;
    this.turnStartedAt = now;
  }

  /** Remaining time of each side at [now], rounded down to the millisecond. */
  read(now: number): Clocks {
    const clocks = { ...this.remaining };
    clocks[this.toMove] -= Math.min(now, this.stoppedAt ?? now) - this.turnStartedAt;
    return {
      white: Math.max(0, Math.floor(clocks.white)),
      black: Math.max(0, Math.floor(clocks.black)),
    };
  }

  /** Whether the side to move has no time left at [now]. */
  hasFlagged(now: number): boolean {
    return this.msUntilFlag(now) <= 0;
  }

  /** Time left to the side to move at [now]. */
  msUntilFlag(now: number): number {
    return this.remaining[this.toMove] - (now - this.turnStartedAt);
  }

  /** The side to move completed its move at [now]. */
  press(now: number): void {
    this.remaining[this.toMove] -= now - this.turnStartedAt;
    this.remaining[this.toMove] += this.incrementMs;
    this.toMove = opponentOf(this.toMove);
    this.turnStartedAt = now;
  }

  /** Freezes the clock at [now], when the game ends. */
  stop(now: number): void {
    this.stoppedAt ??= now;
  }
}
