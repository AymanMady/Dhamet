import { Client } from 'pg';
import { GameJson, GameResultJson } from '../src/engine/engine.types';
import { RoomView } from '../src/rooms/active-room';
import { TestApp } from './support/test-app';

// Several instances of the server sharing one PostgreSQL database, as on
// Vercel: each player is connected to a different instance. Needs a
// disposable database, whose schema is dropped:
//
//   E2E_DATABASE_URL=postgres://dhamet:dhamet@localhost:5436/dhamet_e2e npm run test:e2e
//
// Skipped without E2E_DATABASE_URL.
const url = process.env.E2E_DATABASE_URL;
if (url) {
  process.env.DB_TYPE = 'postgres';
  process.env.DATABASE_URL = url;
  process.env.DB_MIGRATIONS_RUN = 'true';
  process.env.DB_POOL_SIZE = '4';
}
const describeWithDatabase = url ? describe : describe.skip;

// RECONNECT_GRACE_SECONDS is 1 in the e2e tests (see setup-env.ts).
const GRACE_MS = 1000;

async function resetDatabase(connectionString: string): Promise<void> {
  if (!/(e2e|test)/i.test(new URL(connectionString).pathname)) {
    throw new Error('E2E_DATABASE_URL must name a disposable database, e.g. …/dhamet_e2e');
  }
  const client = new Client({ connectionString });
  await client.connect();
  await client.query('DROP SCHEMA public CASCADE');
  await client.query('CREATE SCHEMA public');
  await client.end();
}

describeWithDatabase('Several instances on one PostgreSQL database', () => {
  let a: TestApp;
  let b: TestApp;

  beforeAll(async () => {
    await resetDatabase(url ?? '');
    // Started together: one migrates the empty database while the other waits.
    [a, b] = await Promise.all([TestApp.start(), TestApp.start()]);
  });

  afterAll(async () => {
    await Promise.all([a.stop(), b.stop()]);
  });

  it('plays a game between players connected to different instances', async () => {
    const white = await a.register('w');
    const black = await b.register('b');
    const w = await a.connect(white);
    const k = await b.connect(black);

    w.send('room:create', { color: 'white', rated: true });
    const { room } = await w.next<{ room: RoomView }>('room:updated');
    k.send('room:join', { code: room.code.toLowerCase() });
    await w.next('room:updated', (data: { room: RoomView }) => data.room.players.length === 2);
    await k.next('room:updated', (data: { room: RoomView }) => data.room.players.length === 2);

    // A third player, on either instance, finds the room full.
    const third = await b.connect(await a.register('t'));
    expect((await third.expectError('room:join', { code: room.code })).code).toBe('ROOM_FULL');

    w.send('room:ready', { code: room.code, ready: true });
    k.send('room:ready', { code: room.code, ready: true });
    const started = await w.next<{ gameId: string; game: GameJson }>('game:started');
    await k.next('game:started');

    w.send('game:move', { code: room.code, ply: 0, move: a.legalMove(started.game, 'e4-e5') });
    expect(await k.next('game:moved')).toMatchObject({ ply: 1 });
    await w.next('game:moved');

    // A stale move is refused whatever the instance.
    expect(
      (
        await w.expectError('game:move', {
          code: room.code,
          ply: 0,
          move: a.legalMove(started.game, 'd4-e5'),
        })
      ).code,
    ).toBe('NOT_YOUR_TURN');

    k.send('game:sync', { code: room.code });
    const sync = await k.next<{ game: GameJson }>('game:sync');
    k.send('game:move', { code: room.code, ply: 1, move: b.legalMove(sync.game, 'e6xe4') });
    expect(await w.next('game:moved')).toMatchObject({ ply: 2 });

    k.send('game:resign', { code: room.code });
    const over = await w.next<{ result: GameResultJson; ratingChanges: Record<string, number> }>(
      'game:over',
    );
    expect(over).toMatchObject({
      result: { winner: 'white', reason: 'resignation' },
      ratingChanges: { [white.user.id]: 16, [black.user.id]: -16 },
    });
    await k.next('game:over');

    const saved = await b.http.get(`/api/games/${started.gameId}`).expect(200);
    expect(saved.body.summary).toMatchObject({ status: 'finished', plyCount: 2 });
  });

  it('forfeits a player who left, from the instance of the opponent', async () => {
    const white = await a.register('w');
    const black = await b.register('b');
    const [w, k] = [await a.connect(white), await b.connect(black)];
    const { code, gameId } = await a.startGameAcross(w, k);

    const leftAt = Date.now();
    await k.close();
    expect(await w.next('player:disconnected')).toMatchObject({ code, userId: black.user.id });
    const over = await w.next<{ gameId: string; result: GameResultJson }>(
      'game:over',
      () => true,
      GRACE_MS + 4000,
    );
    expect(Date.now() - leftAt).toBeGreaterThanOrEqual(GRACE_MS - 50);
    expect(over).toMatchObject({ gameId, result: { winner: 'white', reason: 'resignation' } });
  });

  it('lets a player come back on another instance in time', async () => {
    const white = await a.register('w');
    const black = await b.register('b');
    const w = await a.connect(white);
    let k = await b.connect(black);
    const { code, gameId } = await a.startGameAcross(w, k);

    await k.close();
    await w.next('player:disconnected');
    k = await a.connect(black);
    k.send('room:rejoin', { code });
    expect(await k.next('game:sync')).toMatchObject({ gameId, room: { status: 'playing' } });
    expect(await w.next('player:reconnected')).toEqual({ code, userId: black.user.id });
    await new Promise((resolve) => setTimeout(resolve, GRACE_MS + 500));
    expect(w.unread().map((m) => m.event)).not.toContain('game:over');
  });

  it('runs the clock across instances', async () => {
    const white = await a.register('w');
    const black = await b.register('b');
    const [w, k] = [await a.connect(white), await b.connect(black)];
    const timeControl = { initialSeconds: 1.5, incrementSeconds: 0 };
    const { code } = await a.startGameAcross(w, k, { timeControl });
    // White never moves: the instance of either player flags White.
    const over = await k.next<{ result: GameResultJson }>('game:over', () => true, 5000);
    expect(over).toMatchObject({ code, result: { winner: 'black', reason: 'timeout' } });
  });
});
