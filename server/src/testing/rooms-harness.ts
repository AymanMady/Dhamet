import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { AppModule } from '../app.module';
import { configureApp } from '../app.setup';
import { Delivery, RealtimeBus } from '../realtime/realtime-bus';
import { RoomView } from '../rooms/active-room';
import { RoomsService } from '../rooms/rooms.service';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';

/**
 * The whole app on an in-memory database, driven through `RoomsService`
 * without WebSockets: the events it sends are collected in [sent].
 */
export class RoomsHarness {
  readonly sent: Delivery[] = [];
  private accounts = 0;

  private constructor(readonly app: NestExpressApplication) {
    app.get(RealtimeBus).onMessage((message) => {
      this.sent.push(...(message.deliveries ?? []));
    });
  }

  static async start(options: { noticeSeconds?: number } = {}): Promise<RoomsHarness> {
    process.env.DB_TYPE = 'sqljs';
    process.env.DISCONNECT_NOTICE_SECONDS = String(options.noticeSeconds ?? 0);
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const app = moduleRef.createNestApplication<NestExpressApplication>({
      logger: ['error', 'warn'],
    });
    configureApp(app);
    await app.init();
    return new RoomsHarness(app);
  }

  get rooms(): RoomsService {
    return this.app.get(RoomsService);
  }

  get dataSource(): DataSource {
    return this.app.get(DataSource);
  }

  async stop(): Promise<void> {
    await this.app.close();
  }

  account(name = 'player'): Promise<User> {
    return this.app.get(UsersService).create(`${name}_${++this.accounts}`, '', false);
  }

  /** The last `room:updated` sent to [userId]. */
  lastRoom(userId: string): RoomView {
    const update = this.sent.findLast((d) => d.event === 'room:updated' && d.to.includes(userId));
    if (!update) throw new Error(`No room:updated for ${userId}`);
    return (update.data as { room: RoomView }).room;
  }

  /** Events sent to [userId], named [event], in order. */
  received<T>(userId: string, event: string): T[] {
    return this.sent
      .filter((d) => d.event === event && d.to.includes(userId))
      .map((d) => d.data as T);
  }

  /** A waiting room of [white] (host) and [black], both connected and not ready. */
  async room(white: User, black?: User): Promise<string> {
    await this.rooms.create(white.id, { color: 'white' });
    const { code } = this.lastRoom(white.id);
    if (black) await this.rooms.join(black.id, code);
    return code;
  }

  /** A room of [white] and [black] whose game has started. */
  async started(white: User, black: User): Promise<{ code: string; gameId: string }> {
    const code = await this.room(white, black);
    await this.rooms.setReady(white.id, code, true);
    await this.rooms.setReady(black.id, code, true);
    const [started] = this.received<{ gameId: string }>(white.id, 'game:started').slice(-1);
    if (!started) throw new Error('The game did not start');
    return { code, gameId: started.gameId };
  }
}
