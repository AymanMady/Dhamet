import { Inject, Injectable, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { randomInt } from 'node:crypto';
import { DataSource, EntityManager, IsNull } from 'typeorm';
import { AppConfig, appConfig } from '../config/app.config';
import { Color, opponentOf } from '../engine/engine.types';
import { RealtimeBus } from '../realtime/realtime-bus';
import { TransactionRunner, Tx } from '../realtime/transactions';
import { User } from '../users/user.entity';
import { ActiveRoom, RoomView } from './active-room';
import { CreateRoomDto } from './dto/room-messages.dto';
import { GameError } from './game-error';
import { GameplayService, GameSyncData } from './gameplay.service';
import { RoomSeat } from './room.entity';
import { roomKey, RoomStore } from './room-store';

export type RejoinReply =
  { event: 'game:sync'; data: GameSyncData } | { event: 'room:updated'; data: { room: RoomView } };

type RoomTask<T> = (tx: Tx, room: ActiveRoom, now: number) => Promise<T> | T;

function seat(userId: string, color: Color, connected: boolean): RoomSeat {
  return { userId, color, ready: false, connected, leftAt: null, forfeitAt: null };
}

/**
 * Private rooms: creation, joining by code, readiness, leaving, moves, and
 * presence (disconnection and reconnection).
 *
 * The rooms live in the database and may be changed by any instance of the
 * server. Every change runs in a transaction holding the lock of the room
 * ([withRoom]); its events reach the players through the realtime bus once
 * it commits. Time-based rules (forfeits, clocks, closing) are stored as
 * deadlines and applied by whoever touches the room first after them: a
 * request, the timer of an instance watching the room, or a sweep.
 */
@Injectable()
export class RoomsService {
  private readonly logger = new Logger(RoomsService.name);

  constructor(
    private readonly runner: TransactionRunner,
    private readonly store: RoomStore,
    private readonly gameplay: GameplayService,
    private readonly bus: RealtimeBus,
    @InjectDataSource() private readonly dataSource: DataSource,
    @Inject(appConfig.KEY) private readonly settings: AppConfig,
  ) {}

  /** `room:create`. A guest's room is never rated. */
  async create(userId: string, dto: CreateRoomDto): Promise<void> {
    await this.runner.run(`user:${userId}`, async (tx) => {
      const user = await this.member(tx.manager, userId);
      const color: Color =
        dto.color === 'white' || dto.color === 'black'
          ? dto.color
          : randomInt(2)
            ? 'white'
            : 'black';
      const room = await this.store.open(tx, {
        hostId: user.id,
        rated: (dto.rated ?? false) && !user.isGuest,
        timeControl: dto.timeControl
          ? {
              initialSeconds: dto.timeControl.initialSeconds,
              incrementSeconds: dto.timeControl.incrementSeconds,
            }
          : null,
        tournamentMatchId: null,
        players: [seat(user.id, color, true)],
      });
      this.broadcastRoom(tx, room);
    });
  }

  /**
   * Opens the private rated room of a tournament match, inside the
   * transaction of the tournament. Both seats are taken; the players come in
   * with `room:join` or `room:rejoin`.
   */
  async createForMatch(tx: Tx, matchId: string, white: User, black: User): Promise<string> {
    const room = await this.store.open(tx, {
      hostId: white.id,
      rated: true,
      timeControl: null,
      tournamentMatchId: matchId,
      players: [seat(white.id, 'white', false), seat(black.id, 'black', false)],
    });
    return room.code;
  }

  /** `room:join`. A member joining again is treated as `room:rejoin`. */
  join(userId: string, code: string): Promise<RejoinReply | undefined> {
    return this.withRoom(code, async (tx, room, now) => {
      if (room.player(userId)) return this.rejoinInRoom(tx, room, userId, now);
      await this.member(tx.manager, userId);
      const host = room.players[0];
      if (room.status !== 'waiting' || room.players.length >= 2 || !host) {
        throw new GameError('ROOM_FULL', `Room ${code} is full`);
      }
      room.players.push(seat(userId, opponentOf(host.color), true));
      room.entity.expiresAt = null;
      await this.store.refreshUsers(tx, room);
      this.broadcastRoom(tx, room);
      return undefined;
    });
  }

  /**
   * `room:leave`. During a game, leaving resigns. In a waiting room the
   * player gives up their seat, except in a tournament room, whose seats
   * are fixed: there they are only marked not ready.
   */
  leave(userId: string, code: string): Promise<void> {
    return this.withRoom(code, (tx, room, now) => {
      this.seatOf(room, userId);
      return this.leaveInRoom(tx, room, userId, now);
    });
  }

  /**
   * The account of [userId] is being deleted: it leaves every room as with
   * `room:leave`, so a game in progress is resigned. The rooms of its
   * tournament matches not started yet are closed: the tournament records
   * those matches as lost (`TournamentsService.withdraw`).
   */
  async leaveAll(userId: string): Promise<void> {
    for (const code of await this.store.openCodesOf(this.dataSource.manager, userId)) {
      await this.ignoreClosed(
        this.withRoom(code, async (tx, room, now) => {
          if (!room.player(userId)) return;
          if (room.status !== 'waiting' || !room.tournamentMatchId) {
            await this.leaveInRoom(tx, room, userId, now);
            return;
          }
          this.store.close(room, now);
          this.broadcastRoom(tx, room);
        }),
      );
    }
  }

  /**
   * The account [user] was deleted: its connections close as
   * unauthenticated, on every instance. The rooms still listing it show its
   * anonymous name, read from the database.
   */
  async accountDeleted(user: User): Promise<void> {
    await this.bus.publish(this.dataSource.manager, { disconnect: [user.id] });
  }

  /** `room:ready`. The game starts when both players are ready. */
  setReady(userId: string, code: string, ready: boolean): Promise<void> {
    return this.withRoom(code, async (tx, room, now) => {
      const player = this.seatOf(room, userId);
      if (room.status === 'finished') throw new GameError('GAME_OVER', 'The game is over');
      if (room.status === 'playing') return;
      this.markPresentInRoom(tx, room, userId);
      player.ready = ready;
      const full = room.players.length === 2;
      if (full && room.players.every((p) => p.ready && p.connected)) {
        await this.gameplay.startInRoom(tx, room, now);
      } else {
        this.broadcastRoom(tx, room);
      }
    });
  }

  /** `room:rejoin`: `game:sync` during a game, `room:updated` otherwise. */
  rejoin(userId: string, code: string): Promise<RejoinReply> {
    return this.withRoom(code, (tx, room, now) => {
      this.seatOf(room, userId);
      return this.rejoinInRoom(tx, room, userId, now);
    });
  }

  /** `game:move`. */
  move(userId: string, code: string, ply: number, move: unknown): Promise<void> {
    return this.withRoom(code, (tx, room, now) => {
      this.seatOf(room, userId);
      this.markPresentInRoom(tx, room, userId);
      return this.gameplay.moveInRoom(tx, room, userId, ply, move, now);
    });
  }

  /** `game:resign`. */
  resign(userId: string, code: string): Promise<void> {
    return this.withRoom(code, (tx, room, now) => {
      this.seatOf(room, userId);
      this.markPresentInRoom(tx, room, userId);
      return this.gameplay.resignInRoom(tx, room, userId, now, now);
    });
  }

  /** `game:sync`. */
  sync(userId: string, code: string): Promise<GameSyncData> {
    return this.withRoom(code, (tx, room, now) => {
      this.seatOf(room, userId);
      this.markPresentInRoom(tx, room, userId);
      return this.gameplay.syncInRoom(tx, room, now);
    });
  }

  /**
   * The last connection of [userId] to this instance closed at [at]. The
   * others are told after `DISCONNECT_NOTICE_SECONDS`, unless the player is
   * back by then.
   */
  async handleOffline(userId: string, at: number): Promise<void> {
    for (const code of await this.store.openCodesOf(this.dataSource.manager, userId)) {
      await this.ignoreClosed(
        this.withRoom(code, (_tx, room) => {
          const player = room.player(userId);
          if (!player?.connected || player.leftAt !== null) return;
          player.leftAt = at;
        }),
      );
    }
  }

  /** The current state of each open room of [userId], as `room:rejoin` answers it. */
  async stateOf(userId: string): Promise<RejoinReply[]> {
    const replies: RejoinReply[] = [];
    for (const code of await this.store.openCodesOf(this.dataSource.manager, userId)) {
      await this.ignoreClosed(
        this.withRoom(code, async (tx, room, now) => {
          if (!room.player(userId)) return;
          replies.push(
            room.gameId
              ? { event: 'game:sync', data: await this.gameplay.syncInRoom(tx, room, now) }
              : { event: 'room:updated', data: { room: room.view() } },
          );
        }),
      );
    }
    return replies;
  }

  /** Applies what is due in room [code]; nothing if it is closed. */
  async settle(code: string): Promise<void> {
    await this.ignoreClosed(this.withRoom(code, () => undefined));
  }

  /** Settles up to [limit] rooms whose deadline has passed. Returns how many. */
  async sweep(limit = 100): Promise<number> {
    const codes = await this.store.dueCodes(this.dataSource.manager, Date.now(), limit);
    for (const code of codes) {
      try {
        await this.settle(code);
      } catch (error) {
        this.logger.error(`Could not settle room ${code}`, error);
      }
    }
    return codes.length;
  }

  /**
   * Runs [task] on the open room [code], under its lock. What is due is
   * applied before and after. A refusal (GameError) still saves what was
   * done before it, e.g. a game ended by a clock that ran out.
   */
  private async withRoom<T>(code: string, task: RoomTask<T>): Promise<T> {
    const outcome = await this.runner.run(roomKey(code), async (tx) => {
      const room = await this.store.load(tx, code);
      const now = Date.now();
      await this.settleInRoom(tx, room, now);
      let result: { value: T } | { error: GameError };
      if (room.isClosed()) {
        result = { error: new GameError('ROOM_NOT_FOUND', `No active room ${code}`) };
      } else {
        try {
          result = { value: await task(tx, room, now) };
        } catch (error) {
          if (!(error instanceof GameError)) throw error;
          result = { error };
        }
        if (!room.isClosed()) await this.settleInRoom(tx, room, Date.now());
      }
      await this.store.save(tx, room);
      return result;
    });
    if ('error' in outcome) throw outcome.error;
    return outcome.value;
  }

  /** Applies, in order, what is due in [room] at [now]. */
  private async settleInRoom(tx: Tx, room: ActiveRoom, now: number): Promise<void> {
    if (this.expired(room, now)) return;
    const noticeMs = this.settings.disconnectNoticeSeconds * 1000;
    const due = room.players
      .filter((p) => p.leftAt !== null && p.leftAt + noticeMs <= now)
      .sort((a, b) => (a.leftAt ?? 0) - (b.leftAt ?? 0));
    for (const player of due) this.goneInRoom(tx, room, player, now);
    await this.gameplay.settleInRoom(tx, room, now);
    this.expired(room, now);
  }

  /** Closes [room] if its time has come. */
  private expired(room: ActiveRoom, now: number): boolean {
    const expiresAt = room.entity.expiresAt;
    if (room.isClosed() || !expiresAt || expiresAt.getTime() > now) return room.isClosed();
    this.store.close(room, now);
    return true;
  }

  /** [player] left at `player.leftAt` and did not come back: the others are told. */
  private goneInRoom(tx: Tx, room: ActiveRoom, player: RoomSeat, now: number): void {
    const leftAt = player.leftAt ?? now;
    const graceMs = this.settings.reconnectGraceSeconds * 1000;
    player.leftAt = null;
    player.connected = false;
    if (room.status === 'playing') {
      player.forfeitAt = leftAt + graceMs;
      this.send(tx, room.memberIds(player.userId), 'player:disconnected', {
        code: room.code,
        userId: player.userId,
        graceSeconds: Math.max(0, Math.ceil((player.forfeitAt - now) / 1000)),
      });
    } else if (room.status === 'waiting') {
      player.ready = false;
      this.broadcastRoom(tx, room);
      const empty = room.players.every((p) => !p.connected);
      if (empty && !room.tournamentMatchId) room.entity.expiresAt = new Date(leftAt + graceMs);
    }
  }

  private async leaveInRoom(tx: Tx, room: ActiveRoom, userId: string, now: number): Promise<void> {
    if (room.status === 'playing') {
      await this.gameplay.resignInRoom(tx, room, userId, now, now);
      return;
    }
    if (room.status === 'finished') return;
    const player = room.player(userId);
    if (!player) return;
    if (room.tournamentMatchId) {
      player.ready = false;
      this.broadcastRoom(tx, room);
      return;
    }
    room.players.splice(room.players.indexOf(player), 1);
    this.send(tx, [userId], 'room:updated', { room: room.view() });
    const next = room.players[0];
    if (!next) {
      this.store.close(room, now);
      return;
    }
    if (room.hostId === userId) room.hostId = next.userId;
    this.broadcastRoom(tx, room);
  }

  private async rejoinInRoom(
    tx: Tx,
    room: ActiveRoom,
    userId: string,
    now: number,
  ): Promise<RejoinReply> {
    this.markPresentInRoom(tx, room, userId);
    if (room.status === 'playing') {
      return { event: 'game:sync', data: await this.gameplay.syncInRoom(tx, room, now) };
    }
    return { event: 'room:updated', data: { room: room.view() } };
  }

  /**
   * [userId] is active in [room]. Back before the others were told of their
   * disconnection, nothing changes for them; otherwise their forfeit is
   * cancelled and the others are told.
   */
  private markPresentInRoom(tx: Tx, room: ActiveRoom, userId: string): void {
    const player = room.player(userId);
    if (!player) return;
    player.leftAt = null;
    if (player.connected) return;
    player.connected = true;
    player.forfeitAt = null;
    if (room.status === 'playing') {
      this.send(tx, room.memberIds(userId), 'player:reconnected', { code: room.code, userId });
    } else if (room.status === 'waiting') {
      room.entity.expiresAt = null;
      this.send(tx, room.memberIds(userId), 'room:updated', { room: room.view() });
    }
  }

  private seatOf(room: ActiveRoom, userId: string): RoomSeat {
    const player = room.player(userId);
    if (!player) throw new GameError('NOT_IN_ROOM', `You are not in room ${room.code}`);
    return player;
  }

  private broadcastRoom(tx: Tx, room: ActiveRoom): void {
    this.send(tx, room.memberIds(), 'room:updated', { room: room.view() });
  }

  private send(tx: Tx, to: string[], event: string, data: unknown): void {
    if (to.length) tx.publish({ deliveries: [{ to, event, data }] });
  }

  /** The account [userId], unless it was deleted. */
  private async member(manager: EntityManager, userId: string): Promise<User> {
    const user = await manager.findOneBy(User, { id: userId, deletedAt: IsNull() });
    if (!user) throw new GameError('UNAUTHENTICATED', 'Unknown user');
    return user;
  }

  /** Rooms closed meanwhile are no longer of interest. */
  private async ignoreClosed(task: Promise<void>): Promise<void> {
    try {
      await task;
    } catch (error) {
      if (!(error instanceof GameError && error.code === 'ROOM_NOT_FOUND')) throw error;
    }
  }
}
