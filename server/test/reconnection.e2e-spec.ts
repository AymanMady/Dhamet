import { GameJson, GameResultJson } from '../src/engine/engine.types';
import { RoomView } from '../src/rooms/active-room';
import { TestApp } from './support/test-app';

// RECONNECT_GRACE_SECONDS is 1 in the e2e tests (see setup-env.ts).
const GRACE_MS = 1000;

const pause = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

describe('Reconnection', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await TestApp.start();
  });

  afterAll(async () => {
    await t.stop();
  });

  it('resumes the game when the player rejoins within the grace period', async () => {
    const [white, black] = [await t.register('w'), await t.register('b')];
    const w = await t.connect(white);
    let b = await t.connect(black);
    const { code, gameId, game } = await t.startGame(w, b);

    await b.close();
    expect(await w.next('player:disconnected')).toEqual({
      code,
      userId: black.user.id,
      graceSeconds: 1,
    });

    // The game goes on meanwhile: White moves.
    const move = t.legalMove(game, 'e4-e5');
    w.send('game:move', { code, ply: 0, move });
    await w.next('game:moved');

    b = await t.connect(black);
    b.send('room:rejoin', { code });
    const sync = await b.next<{ room: RoomView; gameId: string; game: GameJson }>('game:sync');
    expect(sync.gameId).toBe(gameId);
    expect(sync.room.players.find((p) => p.user.id === black.user.id)?.connected).toBe(true);
    expect(JSON.stringify(sync.game)).toContain('"from":"e4"');
    expect(await w.next('player:reconnected')).toEqual({ code, userId: black.user.id });

    await pause(GRACE_MS + 500);
    expect(w.unread().map((m) => m.event)).not.toContain('game:over');
    const reply = t.legalMove(sync.game, 'e6xe4');
    b.send('game:move', { code, ply: 1, move: reply });
    await expect(w.next('game:moved')).resolves.toMatchObject({ ply: 2 });
  });

  it('forfeits the game of a player who does not come back in time', async () => {
    const [white, black] = [await t.register('w'), await t.register('b')];
    const [w, b] = [await t.connect(white), await t.connect(black)];
    const { code, gameId } = await t.startGame(w, b, { rated: true });

    const leftAt = Date.now();
    await w.close();
    const over = await b.next<{ gameId: string; result: GameResultJson }>(
      'game:over',
      () => true,
      GRACE_MS + 4000,
    );
    expect(Date.now() - leftAt).toBeGreaterThanOrEqual(GRACE_MS - 50);
    expect(over).toMatchObject({
      code,
      gameId,
      result: { winner: 'black', reason: 'resignation' },
      ratingChanges: { [white.user.id]: -16, [black.user.id]: 16 },
    });

    // Rejoining afterwards shows the finished room.
    const again = await t.connect(white);
    again.send('room:rejoin', { code });
    const { room } = await again.next<{ room: RoomView }>('room:updated');
    expect(room).toMatchObject({ status: 'finished', gameId });
  });

  it('keeps a game going while the player has another connection', async () => {
    const [white, black] = [await t.register('w'), await t.register('b')];
    const [w, b] = [await t.connect(white), await t.connect(black)];
    const second = await t.connect(black);
    const { code } = await t.startGame(w, b);
    await b.close();
    await pause(GRACE_MS + 300);
    expect(w.unread().map((m) => m.event)).toEqual([]);
    second.send('game:sync', { code });
    await expect(second.next('game:sync')).resolves.toMatchObject({ room: { status: 'playing' } });
  });

  it('closes a waiting room left empty for the grace period', async () => {
    const host = await t.register('h');
    let h = await t.connect(host);
    h.send('room:create', {});
    const { room } = await h.next<{ room: RoomView }>('room:updated');
    await h.close();

    // Back in time: the room is still there.
    h = await t.connect(host);
    h.send('room:rejoin', { code: room.code });
    const back = await h.next<{ room: RoomView }>('room:updated');
    expect(back.room.players[0]?.connected).toBe(true);

    await h.close();
    await pause(GRACE_MS + 300);
    const late = await t.connect(host);
    expect((await late.expectError('room:rejoin', { code: room.code })).code).toBe(
      'ROOM_NOT_FOUND',
    );
  });
});
