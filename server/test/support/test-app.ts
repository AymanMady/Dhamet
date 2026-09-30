import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { AddressInfo } from 'node:net';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { configureApp } from '../../src/app.setup';
import { EngineService } from '../../src/engine/engine.service';
import { GameJson, LegalMove, MoveJson } from '../../src/engine/engine.types';
import { RoomView } from '../../src/rooms/active-room';
import { UserView } from '../../src/users/user.view';
import { WsClient } from './ws-client';

export interface Account {
  token: string;
  user: UserView;
}

/** The app on a random port, with an in-memory database (see ../setup-env.ts). */
export class TestApp {
  private readonly clients: WsClient[] = [];
  private accounts = 0;

  private constructor(
    readonly app: NestExpressApplication,
    readonly wsUrl: string,
  ) {}

  static async start(): Promise<TestApp> {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const app = moduleRef.createNestApplication<NestExpressApplication>({
      logger: ['error', 'warn'],
    });
    configureApp(app);
    await app.listen(0, '127.0.0.1');
    const { port } = app.getHttpServer().address() as AddressInfo;
    return new TestApp(app, `ws://127.0.0.1:${port}/ws`);
  }

  get http(): ReturnType<typeof request> {
    return request(this.app.getHttpServer());
  }

  async stop(): Promise<void> {
    await Promise.all(this.clients.map((client) => client.close()));
    await this.app.close();
  }

  async register(prefix = 'player'): Promise<Account> {
    const username = `${prefix}_${++this.accounts}`;
    const response = await this.http
      .post('/api/auth/register')
      .send({ username, password: 'password123' })
      .expect(201);
    return response.body as Account;
  }

  async guest(): Promise<Account> {
    const response = await this.http.post('/api/auth/guest').send({}).expect(201);
    return response.body as Account;
  }

  async connect(account: Account): Promise<WsClient> {
    const client = await WsClient.connect(this.wsUrl, account.token);
    this.clients.push(client);
    return client;
  }

  /**
   * Opens a room hosted by [host] (White) and joined by [guest] (Black),
   * then starts its game.
   */
  async startGame(
    host: WsClient,
    guest: WsClient,
    options: {
      rated?: boolean;
      timeControl?: { initialSeconds: number; incrementSeconds: number };
    } = {},
  ): Promise<{ code: string; gameId: string; game: GameJson }> {
    host.send('room:create', { color: 'white', ...options });
    const { room } = await host.next<{ room: RoomView }>('room:updated');
    guest.send('room:join', { code: room.code });
    await guest.next('room:updated', (data: { room: RoomView }) => data.room.players.length === 2);
    host.send('room:ready', { code: room.code, ready: true });
    guest.send('room:ready', { code: room.code, ready: true });
    const started = await host.next<{ room: RoomView; gameId: string; game: GameJson }>(
      'game:started',
    );
    await guest.next('game:started');
    host.clear();
    guest.clear();
    return { code: room.code, gameId: started.gameId, game: started.game };
  }

  /** The legal move written [notation] in [game], computed by the engine. */
  legalMove(game: GameJson, notation: string): MoveJson {
    const moves = this.legalMoves(game);
    const found = moves.find((m) => m.notation === notation);
    if (!found)
      throw new Error(`${notation} is not legal; legal: ${moves.map((m) => m.notation).join(' ')}`);
    return found.move;
  }

  legalMoves(game: GameJson): LegalMove[] {
    const engine = this.app.get(EngineService);
    const id = `test-${Math.random().toString(36).slice(2)}`;
    engine.load(id, game);
    try {
      return engine.legalMoves(id);
    } finally {
      engine.close(id);
    }
  }
}
