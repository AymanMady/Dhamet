import { Inject, Injectable } from '@nestjs/common';
import { EntityManager, In, IsNull, LessThanOrEqual } from 'typeorm';
import { AppConfig, appConfig } from '../config/app.config';
import { Tx } from '../realtime/transactions';
import { User } from '../users/user.entity';
import { toUserView, UserView } from '../users/user.view';
import { ActiveRoom } from './active-room';
import { GameError } from './game-error';
import { Room, RoomSeat } from './room.entity';
import { uniqueRoomCode } from './room-code';
import { TimeControl } from './time-control';

export interface NewRoom {
  hostId: string;
  rated: boolean;
  timeControl: TimeControl | null;
  tournamentMatchId: string | null;
  players: RoomSeat[];
}

/** The lock key of the room [code]: every change of a room holds it (`TransactionRunner`). */
export function roomKey(code: string): string {
  return `room:${code}`;
}

/**
 * The open rooms, in the database. Each is loaded and saved inside a
 * transaction holding its lock, so that the instances of the server change
 * a room one at a time.
 */
@Injectable()
export class RoomStore {
  constructor(@Inject(appConfig.KEY) private readonly settings: AppConfig) {}

  /** Opens a room under a new code; [tx] also takes the lock of that code. */
  async open(tx: Tx, init: NewRoom): Promise<ActiveRoom> {
    const code = await uniqueRoomCode(
      async (candidate) =>
        !(await tx.tryLock(roomKey(candidate))) ||
        (await tx.manager.existsBy(Room, { code: candidate, closedAt: IsNull() })),
    );
    const entity = tx.manager.create(Room, {
      code,
      hostId: init.hostId,
      status: 'waiting',
      rated: init.rated,
      timeControl: init.timeControl,
      tournamentMatchId: init.tournamentMatchId,
      players: init.players,
      gameId: null,
      clock: null,
      expiresAt: null,
      deadlineAt: null,
      closedAt: null,
    });
    copySeats(entity);
    await tx.manager.save(entity);
    return new ActiveRoom(entity, await this.users(tx.manager, init.players));
  }

  /**
   * The open room [code], read under its lock (taken by
   * `TransactionRunner.run(roomKey(code), …)`). Throws ROOM_NOT_FOUND.
   */
  async load(tx: Tx, code: string): Promise<ActiveRoom> {
    const entity = await tx.manager.findOneBy(Room, { code, closedAt: IsNull() });
    if (!entity) throw new GameError('ROOM_NOT_FOUND', `No active room ${code}`);
    return new ActiveRoom(entity, await this.users(tx.manager, entity.players));
  }

  /** Reads the players' profiles again: after a join, or ratings changed by a game. */
  async refreshUsers(tx: Tx, room: ActiveRoom): Promise<void> {
    room.setUsers(await this.users(tx.manager, room.players));
  }

  /**
   * Writes [room] back, with its next deadline, which the instances holding
   * a connection of one of its members will watch.
   */
  async save(tx: Tx, room: ActiveRoom): Promise<void> {
    const entity = room.entity;
    copySeats(entity);
    const deadline = room.isClosed() ? null : this.nextDeadline(room);
    entity.deadlineAt = deadline === null ? null : new Date(deadline);
    await tx.manager.save(entity);
    if (deadline !== null) {
      tx.publish({ watch: { code: room.code, at: deadline, members: room.memberIds() } });
    }
  }

  /** Closes [room] at [now]: it is recorded as finished and its code becomes free. */
  close(room: ActiveRoom, now: number): void {
    room.status = 'finished';
    room.entity.closedAt = new Date(now);
    room.entity.expiresAt = null;
  }

  /** Codes of the open rooms of [userId]. */
  async openCodesOf(manager: EntityManager, userId: string): Promise<string[]> {
    const rooms = await manager.find(Room, {
      select: { code: true },
      where: [
        { whiteId: userId, closedAt: IsNull() },
        { blackId: userId, closedAt: IsNull() },
      ],
    });
    return rooms.map((room) => room.code);
  }

  /** Codes of open rooms whose deadline has passed at [now]. */
  async dueCodes(manager: EntityManager, now: number, limit: number): Promise<string[]> {
    const rooms = await manager.find(Room, {
      select: { code: true },
      where: { closedAt: IsNull(), deadlineAt: LessThanOrEqual(new Date(now)) },
      order: { deadlineAt: 'ASC' },
      take: limit,
    });
    return rooms.map((room) => room.code);
  }

  /** The earliest time something must happen in [room], or null. */
  nextDeadline(room: ActiveRoom): number | null {
    const noticeMs = this.settings.disconnectNoticeSeconds * 1000;
    const times: number[] = [];
    for (const seat of room.players) {
      if (seat.leftAt !== null) times.push(seat.leftAt + noticeMs);
      if (room.status === 'playing' && seat.forfeitAt !== null) times.push(seat.forfeitAt);
    }
    if (room.status === 'playing') {
      const flagAt = room.clock()?.flagAt();
      if (flagAt != null) times.push(flagAt);
    }
    if (room.entity.expiresAt) times.push(room.entity.expiresAt.getTime());
    return times.length ? Math.min(...times) : null;
  }

  private async users(manager: EntityManager, seats: RoomSeat[]): Promise<Map<string, UserView>> {
    if (!seats.length) return new Map();
    // Deleted accounts included: they show their anonymous name.
    const users = await manager.findBy(User, { id: In(seats.map((seat) => seat.userId)) });
    return new Map(users.map((user) => [user.id, toUserView(user)]));
  }
}

/** Keeps the user id columns of each color in step with the seats. */
function copySeats(entity: Room): void {
  entity.whiteId = entity.players.find((seat) => seat.color === 'white')?.userId ?? null;
  entity.blackId = entity.players.find((seat) => seat.color === 'black')?.userId ?? null;
}
