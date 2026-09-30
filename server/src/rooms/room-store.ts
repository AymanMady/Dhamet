import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'node:crypto';
import { Repository } from 'typeorm';
import { ActiveRoom, RoomPlayer } from './active-room';
import { GameError } from './game-error';
import { Room } from './room.entity';
import { uniqueRoomCode } from './room-code';
import { TimeControl } from './time-control';

export interface NewRoom {
  hostId: string;
  rated: boolean;
  timeControl: TimeControl | null;
  tournamentMatchId: string | null;
  players: RoomPlayer[];
}

/** Active rooms, in memory, by code; each one also has a `rooms` row for history. */
@Injectable()
export class RoomStore implements OnModuleDestroy {
  private readonly logger = new Logger(RoomStore.name);
  private readonly rooms = new Map<string, ActiveRoom>();

  constructor(@InjectRepository(Room) private readonly repository: Repository<Room>) {}

  async open(init: NewRoom): Promise<ActiveRoom> {
    const code = uniqueRoomCode((candidate) => this.rooms.has(candidate));
    const room = new ActiveRoom(
      randomUUID(),
      code,
      init.hostId,
      init.rated,
      init.timeControl,
      init.tournamentMatchId,
      init.players,
    );
    this.rooms.set(code, room);
    try {
      await this.repository.insert({
        id: room.id,
        code,
        hostId: init.hostId,
        status: room.status,
        rated: init.rated,
        timeControl: init.timeControl,
        tournamentMatchId: init.tournamentMatchId,
      });
    } catch (error) {
      this.rooms.delete(code);
      throw error;
    }
    return room;
  }

  /** The active room [code]; throws ROOM_NOT_FOUND. */
  get(code: string): ActiveRoom {
    const room = this.rooms.get(code);
    if (!room) throw new GameError('ROOM_NOT_FOUND', `No active room ${code}`);
    return room;
  }

  /** The active room [code] of which [userId] is a member; throws ROOM_NOT_FOUND or NOT_IN_ROOM. */
  getAsMember(code: string, userId: string): ActiveRoom {
    const room = this.get(code);
    if (!room.player(userId)) throw new GameError('NOT_IN_ROOM', `You are not in room ${code}`);
    return room;
  }

  roomsOf(userId: string): ActiveRoom[] {
    return [...this.rooms.values()].filter((room) => room.player(userId));
  }

  async saveStatus(room: ActiveRoom): Promise<void> {
    await this.repository.update(room.id, { status: room.status, hostId: room.hostId });
  }

  /** Closes [room] after [delaySeconds], unless [cancelEviction] is called first. */
  scheduleEviction(room: ActiveRoom, delaySeconds: number): void {
    this.cancelEviction(room);
    room.evictionTimer = setTimeout(() => {
      room
        .run(() => this.close(room))
        .catch((error: unknown) => {
          this.logger.error(error);
        });
    }, delaySeconds * 1000);
  }

  cancelEviction(room: ActiveRoom): void {
    if (room.evictionTimer) clearTimeout(room.evictionTimer);
    room.evictionTimer = null;
  }

  /** Removes [room] from memory; it is recorded as finished. */
  async close(room: ActiveRoom): Promise<void> {
    room.clearTimers();
    if (this.rooms.get(room.code) === room) this.rooms.delete(room.code);
    if (room.status !== 'finished') {
      room.status = 'finished';
      await this.saveStatus(room);
    }
  }

  onModuleDestroy(): void {
    for (const room of this.rooms.values()) room.clearTimers();
    this.rooms.clear();
  }
}
