import { BeforeApplicationShutdown, Logger, UseFilters, UsePipes } from '@nestjs/common';
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
import { BusMessage, RealtimeBus } from '../realtime/realtime-bus';
import { ConnectionRegistry, WS_UNAUTHENTICATED } from './connection-registry';
import { CreateRoomDto, MoveDto, ReadyDto, RoomCodeDto } from './dto/room-messages.dto';
import { GameError } from './game-error';
import { GameSyncData } from './gameplay.service';
import { RoomDeadlines } from './room-deadlines';
import { RejoinReply, RoomsService } from './rooms.service';
import { WsErrorFilter } from './ws-error.filter';
import { wsValidationPipe } from './ws-validation.pipe';

/**
 * `ws://<host>/ws?token=<JWT>`, raw WebSocket, `{event, data}` frames
 * (docs/multiplayer.md, "Temps réel").
 *
 * The connections of this instance receive, through the realtime bus, the
 * events of every instance.
 */
@WebSocketGateway({ path: '/ws' })
@UseFilters(WsErrorFilter)
@UsePipes(wsValidationPipe)
export class RoomsGateway
  implements OnGatewayConnection, OnGatewayDisconnect, BeforeApplicationShutdown
{
  private readonly logger = new Logger(RoomsGateway.name);
  private readonly running = new Set<Promise<unknown>>();
  private shuttingDown = false;

  constructor(
    private readonly auth: AuthService,
    private readonly connections: ConnectionRegistry,
    private readonly rooms: RoomsService,
    private readonly deadlines: RoomDeadlines,
    private readonly bus: RealtimeBus,
  ) {
    bus.onMessage((message) => {
      this.dispatch(message);
    });
    bus.onResume(() => {
      this.track(this.resync());
    });
    connections.onChange((count) => {
      bus.setListening(count > 0);
      deadlines.setSweeping(count > 0);
    });
  }

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
    if (offline && !this.shuttingDown) this.track(this.rooms.handleOffline(offline, Date.now()));
  }

  /**
   * The instance stops (Vercel scales it down, or a deploy replaces it):
   * its players are marked as gone now, so that the instances of their
   * opponents take over, and their apps reconnect to another instance.
   */
  async beforeApplicationShutdown(): Promise<void> {
    this.shuttingDown = true;
    await Promise.allSettled(this.running);
    const now = Date.now();
    for (const userId of this.connections.userIds()) {
      try {
        await this.rooms.handleOffline(userId, now);
      } catch (error) {
        this.logger.error(error);
      }
    }
  }

  @SubscribeMessage('room:create')
  async create(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: CreateRoomDto) {
    await this.rooms.create(await this.userOf(socket), dto);
  }

  @SubscribeMessage('room:join')
  async join(
    @ConnectedSocket() socket: WebSocket,
    @MessageBody() dto: RoomCodeDto,
  ): Promise<RejoinReply | undefined> {
    return this.rooms.join(await this.userOf(socket), dto.code);
  }

  @SubscribeMessage('room:leave')
  async leave(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: RoomCodeDto) {
    await this.rooms.leave(await this.userOf(socket), dto.code);
  }

  @SubscribeMessage('room:ready')
  async ready(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: ReadyDto) {
    await this.rooms.setReady(await this.userOf(socket), dto.code, dto.ready);
  }

  @SubscribeMessage('room:rejoin')
  async rejoin(
    @ConnectedSocket() socket: WebSocket,
    @MessageBody() dto: RoomCodeDto,
  ): Promise<RejoinReply> {
    return this.rooms.rejoin(await this.userOf(socket), dto.code);
  }

  @SubscribeMessage('game:move')
  async move(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: MoveDto) {
    await this.rooms.move(await this.userOf(socket), dto.code, dto.ply, dto.move);
  }

  @SubscribeMessage('game:resign')
  async resign(@ConnectedSocket() socket: WebSocket, @MessageBody() dto: RoomCodeDto) {
    await this.rooms.resign(await this.userOf(socket), dto.code);
  }

  @SubscribeMessage('game:sync')
  async sync(
    @ConnectedSocket() socket: WebSocket,
    @MessageBody() dto: RoomCodeDto,
  ): Promise<WsResponse<GameSyncData>> {
    const userId = await this.userOf(socket);
    return { event: 'game:sync', data: await this.rooms.sync(userId, dto.code) };
  }

  @SubscribeMessage('ping')
  ping(): WsResponse<Record<string, never>> {
    return { event: 'pong', data: {} };
  }

  /** A message from any instance, this one included. */
  private dispatch(message: BusMessage): void {
    for (const { to, event, data } of message.deliveries ?? []) {
      this.connections.broadcast(to, event, data);
    }
    for (const userId of message.disconnect ?? []) this.connections.closeAll(userId);
    const watch = message.watch;
    if (watch && this.connections.hasAny(watch.members)) this.deadlines.watch(watch.code, watch.at);
  }

  /** Runs [task] in the background; the shutdown waits for it. */
  private track(task: Promise<unknown>): void {
    const running = task.catch((error: unknown) => {
      this.logger.error(error);
    });
    this.running.add(running);
    void running.finally(() => this.running.delete(running));
  }

  /**
   * Events may have been missed while this instance could not hear the
   * others: its players get the state of their rooms again.
   */
  private async resync(): Promise<void> {
    for (const userId of this.connections.userIds()) {
      try {
        for (const { event, data } of await this.rooms.stateOf(userId)) {
          this.connections.broadcast([userId], event, data);
        }
      } catch (error) {
        this.logger.error(error);
      }
    }
  }

  /**
   * The user of [socket], once this instance hears the others: the events
   * of the request must reach the connections here too.
   */
  private async userOf(socket: WebSocket): Promise<string> {
    const userId = this.connections.userId(socket);
    if (!userId) throw new GameError('UNAUTHENTICATED', 'Not authenticated');
    await this.bus.ready();
    return userId;
  }
}
