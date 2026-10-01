import { Logger, UseFilters, UsePipes } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WsResponse,
} from '@nestjs/websockets';
import { IncomingMessage } from 'node:http';
import { WebSocket } from 'ws';
import { AuthService } from '../auth/auth.service';
import { ConnectionRegistry, WS_UNAUTHENTICATED } from './connection-registry';
import { CreateRoomDto, MoveDto, ReadyDto, RoomCodeDto } from './dto/room-messages.dto';
import { GameError } from './game-error';
import { GameplayService, GameSyncData } from './gameplay.service';
import { RejoinReply, RoomsService } from './rooms.service';
import { WsErrorFilter } from './ws-error.filter';
import { wsValidationPipe } from './ws-validation.pipe';

/**
 * `ws://<host>/ws?token=<JWT>`, raw WebSocket, `{event, data}` frames
 * (docs/multiplayer.md, "Temps réel").
 */
@WebSocketGateway({ path: '/ws' })
@UseFilters(WsErrorFilter)
@UsePipes(wsValidationPipe)
export class RoomsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(RoomsGateway.name);

  constructor(
    private readonly auth: AuthService,
    private readonly connections: ConnectionRegistry,
    private readonly rooms: RoomsService,
    private readonly gameplay: GameplayService,
  ) {}

  handleConnection(socket: WebSocket, request: IncomingMessage): void {
    const token = new URL(request.url ?? '/', 'http://localhost').searchParams.get('token') ?? '';
    const userId = this.auth.userIdFromToken(token);
    if (!userId) {
      socket.close(WS_UNAUTHENTICATED, 'Unauthenticated');
      return;
    }
    // Registered at once, for the messages that follow; a token outliving
    // its deleted account is refused as soon as the database answers.
    this.connections.add(socket, userId);
    this.auth
      .authenticate(token)
      .then((user) => {
        if (!user) socket.close(WS_UNAUTHENTICATED, 'Unauthenticated');
      })
      .catch((error: unknown) => {
        this.logger.error(error);
      });
  }

  handleDisconnect(socket: WebSocket): void {
    const offline = this.connections.remove(socket);
    if (offline) {
      this.rooms.handleOffline(offline).catch((error: unknown) => {
        this.logger.error(error);
      });
    }
  }

  @SubscribeMessage('room:create')
  async create(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: CreateRoomDto) {
    await this.rooms.create(this.userOf(socket), dto);
  }

  @SubscribeMessage('room:join')
  join(
    @ConnectedSocket() socket: WebSocket,
    @MessageBody() dto: RoomCodeDto,
  ): Promise<RejoinReply | undefined> {
    return this.rooms.join(this.userOf(socket), dto.code);
  }

  @SubscribeMessage('room:leave')
  async leave(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: RoomCodeDto) {
    await this.rooms.leave(this.userOf(socket), dto.code);
  }

  @SubscribeMessage('room:ready')
  async ready(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: ReadyDto) {
    await this.rooms.setReady(this.userOf(socket), dto.code, dto.ready);
  }

  @SubscribeMessage('room:rejoin')
  rejoin(
    @ConnectedSocket() socket: WebSocket,
    @MessageBody() dto: RoomCodeDto,
  ): Promise<RejoinReply> {
    return this.rooms.rejoin(this.userOf(socket), dto.code);
  }

  @SubscribeMessage('game:move')
  async move(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: MoveDto) {
    await this.gameplay.move(this.userOf(socket), dto.code, dto.ply, dto.move);
  }

  @SubscribeMessage('game:resign')
  async resign(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: RoomCodeDto) {
    await this.gameplay.resign(this.userOf(socket), dto.code);
  }

  @SubscribeMessage('game:sync')
  async sync(
    @ConnectedSocket() socket: WebSocket,
    @MessageBody() dto: RoomCodeDto,
  ): Promise<WsResponse<GameSyncData>> {
    return { event: 'game:sync', data: await this.gameplay.sync(this.userOf(socket), dto.code) };
  }

  @SubscribeMessage('ping')
  ping(): WsResponse<Record<string, never>> {
    return { event: 'pong', data: {} };
  }

  private userOf(socket: WebSocket): string {
    const userId = this.connections.userId(socket);
    if (!userId) throw new GameError('UNAUTHENTICATED', 'Not authenticated');
    return userId;
  }
}
