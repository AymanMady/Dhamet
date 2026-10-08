import { Color, opponentOf } from '../engine/engine.types';
import { TimeControl } from './time-control';

export type Clocks = Record<Color, number>;

/** What the database keeps of a clock (times in milliseconds since the epoch). */
export interface ClockState {
  remaining: Clocks;
  incrementMs: number;
  toMove: Color;
  turnStartedAt: number;
  stoppedAt: number | null;
}

/**
 * Server-side chess clock (times in milliseconds, [now] from `Date.now()`).
 * Only the side to move loses time; a move adds the increment to the mover.
 */
export class GameClock {
  private s: ClockState;

  constructor(timeControl: TimeControl, firstToMove: Color, now: number) {
    const initial = timeControl.initialSeconds * 1000;
    this.s = {
      remaining: { white: initial, black: initial },
      incrementMs: timeControl.incrementSeconds * 1000,
      toMove: firstToMove,
      turnStartedAt: now,
      stoppedAt: null,
    };
  }

  /** The clock saved as [state]. */
  static restore(state: ClockState): GameClock {
    const clock = new GameClock({ initialSeconds: 0, incrementSeconds: 0 }, state.toMove, 0);
    clock.s = structuredClone(state);
    return clock;
  }

  state(): ClockState {
    return structuredClone(this.s);
  }

  /** Remaining time of each side at [now], rounded down to the millisecond. */
  read(now: number): Clocks {
    const clocks = { ...this.s.remaining };
    clocks[this.s.toMove] -= Math.min(now, this.s.stoppedAt ?? now) - this.s.turnStartedAt;
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
    return this.s.remaining[this.s.toMove] - (now - this.s.turnStartedAt);
  }

  /** When the side to move runs out of time; null once the clock is stopped. */
  flagAt(): number | null {
    return this.s.stoppedAt === null
      ? this.s.turnStartedAt + this.s.remaining[this.s.toMove]
      : null;
  }

  /** The side to move completed its move at [now]. */
  press(now: number): void {
    const { remaining, toMove } = this.s;
    remaining[toMove] -= now - this.s.turnStartedAt;
    remaining[toMove] += this.s.incrementMs;
    this.s.toMove = opponentOf(toMove);
    this.s.turnStartedAt = now;
  }

  /** Freezes the clock at [now], when the game ends. */
  stop(now: number): void {
    this.s.stoppedAt ??= now;
  }
}
