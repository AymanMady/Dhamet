import { Inject, Injectable, Logger } from '@nestjs/common';
import { randomInt } from 'node:crypto';
import { AppConfig, appConfig } from '../config/app.config';
import { opponentOf } from '../engine/engine.types';
import { User } from '../users/user.entity';
import { toUserView, UserView } from '../users/user.view';
import { UsersService } from '../users/users.service';
import { ActiveRoom, RoomView } from './active-room';
import { ConnectionRegistry } from './connection-registry';
import { CreateRoomDto } from './dto/room-messages.dto';
import { GameError } from './game-error';
import { GameplayService, GameSyncData } from './gameplay.service';
import { RoomStore } from './room-store';

export type RejoinReply =
  { event: 'game:sync'; data: GameSyncData } | { event: 'room:updated'; data: { room: RoomView } };

/**
 * Private rooms: creation, joining by code, readiness, leaving, and
 * presence (disconnection and reconnection).
 */
@Injectable()
export class RoomsService {
  private readonly logger = new Logger(RoomsService.name);

  constructor(
    private readonly store: RoomStore,
    private readonly gameplay: GameplayService,
    private readonly connections: ConnectionRegistry,
    private readonly users: UsersService,
    @Inject(appConfig.KEY) private readonly settings: AppConfig,
  ) {}

  /** `room:create`. A guest's room is never rated. */
  async create(userId: string, dto: CreateRoomDto): Promise<void> {
    const user = await this.member(userId);
    const color =
      dto.color === 'white' || dto.color === 'black' ? dto.color : randomInt(2) ? 'white' : 'black';
    const room = await this.store.open({
      hostId: user.id,
      rated: (dto.rated ?? false) && !user.isGuest,
      timeControl: dto.timeControl
        ? {
            initialSeconds: dto.timeControl.initialSeconds,
            incrementSeconds: dto.timeControl.incrementSeconds,
          }
        : null,
      tournamentMatchId: null,
      players: [{ user, color, ready: false, connected: true }],
    });
    this.broadcastRoom(room);
  }

  /**
   * Opens the private rated room of a tournament match. Both seats are
   * taken; the players come in with `room:join` or `room:rejoin`.
   */
  async createForMatch(matchId: string, white: User, black: User): Promise<string> {
    const room = await this.store.open({
      hostId: white.id,
      rated: true,
      timeControl: null,
      tournamentMatchId: matchId,
      players: [
        { user: toUserView(white), color: 'white', ready: false, connected: false },
        { user: toUserView(black), color: 'black', ready: false, connected: false },
      ],
    });
    return room.code;
  }

  /** `room:join`. A member joining again is treated as `room:rejoin`. */
  async join(userId: string, code: string): Promise<RejoinReply | undefined> {
    const room = this.store.get(code);
    if (room.player(userId)) return this.rejoin(userId, code);
    const user = await this.member(userId);
    return room.run(() => {
      if (room.player(userId)) return this.rejoinInRoom(room, userId);
      const host = room.players[0];
      if (room.status !== 'waiting' || room.players.length >= 2 || !host) {
        throw new GameError('ROOM_FULL', `Room ${code} is full`);
      }
      room.players.push({
        user,
        color: opponentOf(host.color),
        ready: false,
        connected: true,
      });
      this.store.cancelEviction(room);
      this.broadcastRoom(room);
      return undefined;
    });
  }

  /**
   * `room:leave`. During a game, leaving resigns. In a waiting room the
   * player gives up their seat, except in a tournament room, whose seats
   * are fixed: there they are only marked not ready.
   */
  async leave(userId: string, code: string): Promise<void> {
    const room = this.store.getAsMember(code, userId);
    await room.run(async () => {
      if (room.status === 'playing') return this.gameplay.resignInRoom(room, userId);
      if (room.status === 'finished') return;
      const player = room.player(userId);
      if (!player) return;
      if (room.tournamentMatchId) {
        player.ready = false;
        this.broadcastRoom(room);
        return;
      }
      room.players.splice(room.players.indexOf(player), 1);
      this.connections.broadcast([userId], 'room:updated', { room: room.view() });
      const next = room.players[0];
      if (!next) return this.store.close(room);
      if (room.hostId === userId) {
        room.hostId = next.user.id;
        await this.store.saveStatus(room);
      }
      this.broadcastRoom(room);
    });
  }

  /** `room:ready`. The game starts when both players are ready. */
  async setReady(userId: string, code: string, ready: boolean): Promise<void> {
    const room = this.store.getAsMember(code, userId);
    await room.run(async () => {
      if (room.status === 'finished') throw new GameError('GAME_OVER', 'The game is over');
      if (room.status === 'playing') return;
      const player = room.player(userId);
      if (!player) return;
      this.markPresentInRoom(room, userId);
      player.ready = ready;
      const full = room.players.length === 2;
      if (full && room.players.every((p) => p.ready && p.connected)) {
        await this.gameplay.startInRoom(room);
      } else {
        this.broadcastRoom(room);
      }
    });
  }

  /** `room:rejoin`: `game:sync` during a game, `room:updated` otherwise. */
  async rejoin(userId: string, code: string): Promise<RejoinReply> {
    const room = this.store.getAsMember(code, userId);
    return await room.run(() => this.rejoinInRoom(room, userId));
  }

  /** The last connection of [userId] closed. */
  async handleOffline(userId: string): Promise<void> {
    for (const room of this.store.roomsOf(userId)) {
      await room
        .run(() => {
          const player = room.player(userId);
          if (!player?.connected) return;
          player.connected = false;
          if (room.status === 'playing') {
            this.gameplay.startForfeitTimerInRoom(room, userId);
            this.connections.broadcast(room.memberIds(userId), 'player:disconnected', {
              code: room.code,
              userId,
              graceSeconds: this.settings.reconnectGraceSeconds,
            });
          } else if (room.status === 'waiting') {
            player.ready = false;
            this.broadcastRoom(room);
            const empty = room.players.every((p) => !p.connected);
            if (empty && !room.tournamentMatchId) {
              this.store.scheduleEviction(room, this.settings.reconnectGraceSeconds);
            }
          }
        })
        .catch((error: unknown) => {
          this.logger.error(error);
        });
    }
  }

  private rejoinInRoom(room: ActiveRoom, userId: string): RejoinReply {
    this.markPresentInRoom(room, userId);
    if (room.status === 'playing') {
      return { event: 'game:sync', data: this.gameplay.syncInRoom(room) };
    }
    return { event: 'room:updated', data: { room: room.view() } };
  }

  /** [userId] is back in [room]: cancels their forfeit and tells the others. */
  private markPresentInRoom(room: ActiveRoom, userId: string): void {
    const player = room.player(userId);
    if (!player || player.connected) return;
    player.connected = true;
    if (room.status === 'playing') {
      this.gameplay.cancelForfeitTimerInRoom(room, userId);
      this.connections.broadcast(room.memberIds(userId), 'player:reconnected', {
        code: room.code,
        userId,
      });
    } else if (room.status === 'waiting') {
      this.store.cancelEviction(room);
      this.connections.broadcast(room.memberIds(userId), 'room:updated', { room: room.view() });
    }
  }

  private broadcastRoom(room: ActiveRoom): void {
    this.connections.broadcast(room.memberIds(), 'room:updated', { room: room.view() });
  }

  private async member(userId: string): Promise<UserView> {
    const user = await this.users.findById(userId);
    if (!user) throw new GameError('UNAUTHENTICATED', 'Unknown user');
    return toUserView(user);
  }
}
