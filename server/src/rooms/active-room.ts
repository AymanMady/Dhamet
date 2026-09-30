import { SerialQueue } from '../common/serial-queue';
import { Color, EngineSnapshot } from '../engine/engine.types';
import { UserView } from '../users/user.view';
import { GameClock } from './game-clock';
import { RoomStatus } from './room.entity';
import { TimeControl } from './time-control';

export interface RoomPlayer {
  user: UserView;
  color: Color;
  ready: boolean;
  connected: boolean;
}

/** The game of a room, from its start; kept after its end for `game:sync`. */
export interface ActiveGame {
  id: string;
  rated: boolean;
  snapshot: EngineSnapshot;
  clock: GameClock | null;
}

/** `room` in docs/multiplayer.md. */
export interface RoomView {
  code: string;
  status: RoomStatus;
  hostId: string;
  rated: boolean;
  timeControl: TimeControl | null;
  players: { user: UserView; color: Color; ready: boolean; connected: boolean }[];
  gameId: string | null;
}

/**
 * A room in memory. Its state changes only inside [run], one task at a
 * time, so that moves, resignations, clocks and forfeits never interleave.
 */
export class ActiveRoom {
  status: RoomStatus = 'waiting';
  game: ActiveGame | null = null;
  /** Forfeits pending for disconnected players, by user id. */
  readonly forfeitTimers = new Map<string, NodeJS.Timeout>();
  flagTimer: NodeJS.Timeout | null = null;
  evictionTimer: NodeJS.Timeout | null = null;
  private readonly queue = new SerialQueue();

  constructor(
    readonly id: string,
    readonly code: string,
    public hostId: string,
    readonly rated: boolean,
    readonly timeControl: TimeControl | null,
    /** Set for the rooms of tournament matches, whose seats are fixed. */
    readonly tournamentMatchId: string | null,
    readonly players: RoomPlayer[],
  ) {}

  player(userId: string): RoomPlayer | undefined {
    return this.players.find((player) => player.user.id === userId);
  }

  playerWithColor(color: Color): RoomPlayer {
    const player = this.players.find((p) => p.color === color);
    if (!player) throw new Error(`Room ${this.code} has no ${color} player`);
    return player;
  }

  /** User ids of the members, except [excluded]. */
  memberIds(excluded?: string): string[] {
    return this.players.map((player) => player.user.id).filter((id) => id !== excluded);
  }

  run<T>(task: () => Promise<T> | T): Promise<T> {
    return this.queue.run(task);
  }

  clearTimers(): void {
    for (const timer of this.forfeitTimers.values()) clearTimeout(timer);
    this.forfeitTimers.clear();
    if (this.flagTimer) clearTimeout(this.flagTimer);
    if (this.evictionTimer) clearTimeout(this.evictionTimer);
    this.flagTimer = null;
    this.evictionTimer = null;
  }

  view(): RoomView {
    return {
      code: this.code,
      status: this.status,
      hostId: this.hostId,
      rated: this.rated,
      timeControl: this.timeControl,
      players: this.players.map(({ user, color, ready, connected }) => ({
        user,
        color,
        ready,
        connected,
      })),
      gameId: this.game?.id ?? null,
    };
  }
}
