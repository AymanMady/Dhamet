import { Color } from '../engine/engine.types';
import { UserView } from '../users/user.view';
import { Clocks, GameClock } from './game-clock';
import { Room, RoomSeat, RoomStatus } from './room.entity';
import { TimeControl } from './time-control';

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
 * An open room, loaded from the database inside the transaction that holds
 * its lock (`RoomStore.load`). Changes are written back by `RoomStore.save`.
 */
export class ActiveRoom {
  constructor(
    readonly entity: Room,
    /** The public profile of each player, by user id. */
    private users: Map<string, UserView>,
  ) {}

  get id(): string {
    return this.entity.id;
  }

  get code(): string {
    return this.entity.code;
  }

  get status(): RoomStatus {
    return this.entity.status;
  }

  set status(status: RoomStatus) {
    this.entity.status = status;
  }

  get hostId(): string {
    return this.entity.hostId;
  }

  set hostId(hostId: string) {
    this.entity.hostId = hostId;
  }

  get rated(): boolean {
    return this.entity.rated;
  }

  get timeControl(): TimeControl | null {
    return this.entity.timeControl;
  }

  /** Set for the rooms of tournament matches, whose seats are fixed. */
  get tournamentMatchId(): string | null {
    return this.entity.tournamentMatchId;
  }

  get players(): RoomSeat[] {
    return this.entity.players;
  }

  get gameId(): string | null {
    return this.entity.gameId;
  }

  /** A method, not a getter: it changes during a request. */
  isClosed(): boolean {
    return this.entity.closedAt !== null;
  }

  player(userId: string): RoomSeat | undefined {
    return this.players.find((player) => player.userId === userId);
  }

  playerWithColor(color: Color): RoomSeat {
    const player = this.players.find((p) => p.color === color);
    if (!player) throw new Error(`Room ${this.code} has no ${color} player`);
    return player;
  }

  /** User ids of the members, except [excluded]. */
  memberIds(excluded?: string): string[] {
    return this.players.map((player) => player.userId).filter((id) => id !== excluded);
  }

  user(userId: string): UserView {
    const user = this.users.get(userId);
    if (!user) throw new Error(`Room ${this.code}: unknown user ${userId}`);
    return user;
  }

  setUsers(users: Map<string, UserView>): void {
    this.users = users;
  }

  /** The clock of the game, if it has one. */
  clock(): GameClock | null {
    return this.entity.clock ? GameClock.restore(this.entity.clock) : null;
  }

  setClock(clock: GameClock | null): void {
    this.entity.clock = clock?.state() ?? null;
  }

  /** `{clocks}` at [now] for the events of a game with a clock, `{}` otherwise. */
  clocksAt(now: number): { clocks?: Clocks } {
    const clock = this.clock();
    return clock ? { clocks: clock.read(now) } : {};
  }

  view(): RoomView {
    return {
      code: this.code,
      status: this.status,
      hostId: this.hostId,
      rated: this.rated,
      timeControl: this.timeControl,
      players: this.players.map(({ userId, color, ready, connected }) => ({
        user: this.user(userId),
        color,
        ready,
        connected,
      })),
      gameId: this.gameId,
    };
  }
}
