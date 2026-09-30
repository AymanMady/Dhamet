import { EngineService } from '../src/engine/engine.service';
import { GameJson, GameResultJson, MoveJson } from '../src/engine/engine.types';
import { RoomView } from '../src/rooms/active-room';
import { GameSummary } from '../src/games/games.service';
import { UserView } from '../src/users/user.view';
import { Account, TestApp } from './support/test-app';
import { WsClient } from './support/ws-client';

interface Moved {
  code: string;
  gameId: string;
  ply: number;
  move: MoveJson;
  clocks?: unknown;
}

interface Over {
  code: string;
  gameId: string;
  result: GameResultJson;
  ratingChanges?: Record<string, number>;
}

describe('Online games (WebSocket)', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await TestApp.start();
  });

  afterAll(async () => {
    await t.stop();
  });

  async function currentGame(gameId: string): Promise<GameJson> {
    const response = await t.http.get(`/api/games/${gameId}`).expect(200);
    return (response.body as { game: GameJson }).game;
  }

  /** [mover] plays [notation]; both players receive `game:moved`. */
  async function play(
    mover: WsClient,
    other: WsClient,
    code: string,
    gameId: string,
    ply: number,
    notation: string,
  ): Promise<Moved> {
    const move = t.legalMove(await currentGame(gameId), notation);
    mover.send('game:move', { code, ply, move });
    const moved = await mover.next<Moved>('game:moved', (m) => m.ply === ply + 1);
    expect(await other.next<Moved>('game:moved', (m) => m.ply === ply + 1)).toEqual(moved);
    expect(moved).toEqual({ code, gameId, ply: ply + 1, move });
    return moved;
  }

  describe('a rated game between two accounts', () => {
    let alice: Account;
    let bob: Account;
    let carol: Account;
    let a: WsClient;
    let b: WsClient;
    let c: WsClient;
    let code: string;
    let gameId: string;

    beforeAll(async () => {
      [alice, bob, carol] = [
        await t.register('alice'),
        await t.register('bob'),
        await t.register('carol'),
      ];
      [a, b, c] = [await t.connect(alice), await t.connect(bob), await t.connect(carol)];
    });

    it('creates a private room with a 6-character code', async () => {
      a.send('room:create', { color: 'white', rated: true });
      const { room } = await a.next<{ room: RoomView }>('room:updated');
      expect(room).toEqual({
        code: expect.stringMatching(/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/),
        status: 'waiting',
        hostId: alice.user.id,
        rated: true,
        timeControl: null,
        players: [{ user: alice.user, color: 'white', ready: false, connected: true }],
        gameId: null,
      });
      code = room.code;
    });

    it('lets a second player join by code (case-insensitive)', async () => {
      b.send('room:join', { code: code.toLowerCase() });
      const forBob = await b.next<{ room: RoomView }>('room:updated');
      const forAlice = await a.next<{ room: RoomView }>('room:updated');
      expect(forAlice).toEqual(forBob);
      expect(forBob.room.players).toEqual([
        { user: alice.user, color: 'white', ready: false, connected: true },
        { user: bob.user, color: 'black', ready: false, connected: true },
      ]);
    });

    it('refuses a third player (ROOM_FULL)', async () => {
      expect(await c.expectError('room:join', { code })).toEqual({
        code: 'ROOM_FULL',
        message: expect.any(String),
        event: 'room:join',
      });
    });

    it('refuses moves before the start (GAME_NOT_STARTED)', async () => {
      const error = await a.expectError('game:move', { code, ply: 0, move: {} });
      expect(error.code).toBe('GAME_NOT_STARTED');
    });

    it('starts when both players are ready', async () => {
      a.send('room:ready', { code, ready: true });
      const update = await b.next<{ room: RoomView }>('room:updated', (d) =>
        d.room.players.some((p) => p.ready),
      );
      expect(update.room.players.map((p) => p.ready)).toEqual([true, false]);
      b.send('room:ready', { code, ready: true });
      const started = await a.next<{ room: RoomView; gameId: string; game: GameJson }>(
        'game:started',
      );
      expect(await b.next('game:started')).toEqual(started);
      expect(started.room).toMatchObject({ code, status: 'playing', gameId: started.gameId });
      expect(started.game).toMatchObject({
        format: 'dhamet.game',
        undoPolicy: { enabled: false, maxDepth: null },
        declaredResult: null,
        history: { moves: [], cursor: 0 },
      });
      gameId = started.gameId;
      a.clear();
      b.clear();
    });

    it('broadcasts legal moves to both players', async () => {
      await play(a, b, code, gameId, 0, 'd4-e5');
      await play(b, a, code, gameId, 1, 'f6xd4');
    });

    it('refuses a move out of turn (NOT_YOUR_TURN)', async () => {
      const game = await currentGame(gameId);
      const move = t.legalMove(game, 'c3xe5');
      expect(await b.expectError('game:move', { code, ply: 2, move })).toMatchObject({
        code: 'NOT_YOUR_TURN',
        event: 'game:move',
      });
    });

    it('refuses a stale ply (STALE_PLY)', async () => {
      const move = t.legalMove(await currentGame(gameId), 'c3xe5');
      const error = await a.expectError('game:move', { code, ply: 1, move });
      expect(error.code).toBe('STALE_PLY');
    });

    it('refuses an illegal move (ILLEGAL_MOVE), e.g. ignoring a mandatory capture', async () => {
      const quiet = { piece: 'w', from: 'e4', path: ['e5'], captured: [], promotes: false };
      const error = await a.expectError('game:move', { code, ply: 2, move: quiet });
      expect(error.code).toBe('ILLEGAL_MOVE');
      const forged = { ...t.legalMove(await currentGame(gameId), 'c3xe5'), captured: ['d5'] };
      expect((await a.expectError('game:move', { code, ply: 2, move: forged })).code).toBe(
        'ILLEGAL_MOVE',
      );
    });

    it('refuses a player who is not in the room (NOT_IN_ROOM)', async () => {
      const move = t.legalMove(await currentGame(gameId), 'c3xe5');
      expect((await c.expectError('game:move', { code, ply: 2, move })).code).toBe('NOT_IN_ROOM');
      expect((await c.expectError('game:resign', { code })).code).toBe('NOT_IN_ROOM');
    });

    it('refuses malformed payloads (INVALID_MESSAGE)', async () => {
      for (const data of [
        { code, ply: -1, move: {} },
        { code, ply: 2 },
        { ply: 2, move: {} },
      ]) {
        const error = await a.expectError('game:move', data);
        expect(error).toMatchObject({ code: 'INVALID_MESSAGE', event: 'game:move' });
      }
    });

    it('sends the full game on game:sync', async () => {
      a.send('game:sync', { code });
      const sync = await a.next<{ room: RoomView; gameId: string; game: GameJson }>('game:sync');
      expect(sync.gameId).toBe(gameId);
      expect(sync.room.status).toBe('playing');
      expect(sync.game).toEqual(await currentGame(gameId));
      expect(sync).not.toHaveProperty('clocks');
    });

    it('ends on resignation with rating changes', async () => {
      await play(a, b, code, gameId, 2, 'c3xe5');
      b.send('game:resign', { code });
      const over = await a.next<Over>('game:over');
      expect(await b.next('game:over')).toEqual(over);
      expect(over).toEqual({
        code,
        gameId,
        result: { winner: 'white', reason: 'resignation' },
        ratingChanges: { [alice.user.id]: 16, [bob.user.id]: -16 },
      });
    });

    it('refuses moves once the game is over (GAME_OVER)', async () => {
      const error = await b.expectError('game:move', { code, ply: 3, move: {} });
      expect(error.code).toBe('GAME_OVER');
    });

    it('updates ratings and results of both players', async () => {
      const winner = (await t.http.get(`/api/users/${alice.user.id}`).expect(200)).body as UserView;
      const loser = (await t.http.get(`/api/users/${bob.user.id}`).expect(200)).body as UserView;
      expect(winner).toMatchObject({ rating: 1216, wins: 1, losses: 0, gamesPlayed: 1 });
      expect(loser).toMatchObject({ rating: 1184, wins: 0, losses: 1, gamesPlayed: 1 });
    });

    it('serves the game for replay: GET /api/games/:id', async () => {
      const response = await t.http.get(`/api/games/${gameId}`).expect(200);
      const { summary, game } = response.body as { summary: GameSummary; game: GameJson };
      expect(summary).toMatchObject({
        id: gameId,
        roomCode: code,
        status: 'finished',
        result: { winner: 'white', reason: 'resignation' },
        rated: true,
        plyCount: 3,
        white: { id: alice.user.id, rating: 1216 },
        black: { id: bob.user.id, rating: 1184 },
      });
      expect(summary.finishedAt).toEqual(expect.any(String));

      // The saved moves replay in the engine, with server timestamps.
      const engine = t.app.get(EngineService);
      const replay = engine.load(`replay-${gameId}`, game);
      engine.close(`replay-${gameId}`);
      expect(replay.plyCount).toBe(3);
      expect(replay.result).toEqual({ winner: 'white', reason: 'resignation' });
      expect(JSON.stringify(game)).toMatch(/"timestamp":"\d{4}-\d\d-\d\dT[\d:.]+Z"/);
      await t.http.get('/api/games/00000000-0000-4000-8000-000000000000').expect(404);
    });

    it('lists the games of a player: GET /api/users/:id/games', async () => {
      const response = await t.http.get(`/api/users/${bob.user.id}/games?limit=5`).expect(200);
      expect(response.body).toEqual([expect.objectContaining({ id: gameId, status: 'finished' })]);
      await t.http.get(`/api/users/${carol.user.id}/games`).expect(200, []);
    });

    it('ranks accounts by rating: GET /api/leaderboard', async () => {
      await t.guest(); // guests are not ranked
      const response = await t.http.get('/api/leaderboard').expect(200);
      const board = response.body as { rank: number; user: UserView }[];
      expect(board.map((entry) => entry.rank)).toEqual(board.map((_, i) => i + 1));
      const ratings = board.map((entry) => entry.user.rating);
      expect(ratings).toEqual([...ratings].sort((x, y) => y - x));
      expect(board.every((entry) => !entry.user.isGuest)).toBe(true);
      expect(board[0]?.user.id).toBe(alice.user.id);
      expect(board.at(-1)?.user.id).toBe(bob.user.id);
      const page = await t.http.get('/api/leaderboard?limit=1&offset=1').expect(200);
      expect(page.body).toEqual([board[1]]);
      await t.http.get('/api/leaderboard?limit=0').expect(400);
    });
  });

  describe('unrated games', () => {
    it('never rates a game with a guest, but counts its result', async () => {
      const host = await t.register('host');
      const visitor = await t.guest();
      const [h, v] = [await t.connect(host), await t.connect(visitor)];
      const { code, gameId } = await t.startGame(h, v, { rated: true });
      h.send('game:resign', { code });
      const over = await v.next<Over>('game:over');
      expect(over).toEqual({ code, gameId, result: { winner: 'black', reason: 'resignation' } });
      const summary = (await t.http.get(`/api/games/${gameId}`).expect(200)).body as {
        summary: GameSummary;
      };
      expect(summary.summary.rated).toBe(false);
      const hostAfter = (await t.http.get(`/api/users/${host.user.id}`)).body as UserView;
      const visitorAfter = (await t.http.get(`/api/users/${visitor.user.id}`)).body as UserView;
      expect(hostAfter).toMatchObject({ rating: 1200, losses: 1 });
      expect(visitorAfter).toMatchObject({ rating: 1200, wins: 1 });
    });

    it('does not rate a guest room, even if asked', async () => {
      const visitor = await t.guest();
      const v = await t.connect(visitor);
      v.send('room:create', { rated: true });
      const { room } = await v.next<{ room: RoomView }>('room:updated');
      expect(room.rated).toBe(false);
      expect(['white', 'black']).toContain(room.players[0]?.color);
    });

    it('treats leaving a game as resigning', async () => {
      const [x, y] = [await t.register('leaver'), await t.register('stayer')];
      const [cx, cy] = [await t.connect(x), await t.connect(y)];
      const { code } = await t.startGame(cx, cy);
      cx.send('room:leave', { code });
      const over = await cy.next<Over>('game:over');
      expect(over.result).toEqual({ winner: 'black', reason: 'resignation' });
      expect(over).not.toHaveProperty('ratingChanges');
    });
  });

  it('plays a whole game to its end by the rules, as two clients would', async () => {
    const [x, y] = [await t.register('white'), await t.register('black')];
    const [cx, cy] = [await t.connect(x), await t.connect(y)];
    const { code, gameId, game } = await t.startGame(cx, cy, { rated: true });

    // Each client mirrors the game with its own engine, as the Flutter app does.
    const engine = t.app.get(EngineService);
    const mirror = `mirror-${gameId}`;
    engine.load(mirror, game);
    let seed = 7;
    const random = (n: number): number => {
      seed = (seed * 1103515245 + 12345) % 2 ** 31;
      return seed % n;
    };
    let over: Over | undefined;
    for (let ply = 0; ply < 1000 && !over; ply++) {
      const moves = engine.legalMoves(mirror);
      const chosen = moves[random(moves.length)];
      if (!chosen) throw new Error('No legal move but no game over');
      const [mover, other] = ply % 2 === 0 ? [cx, cy] : [cy, cx];
      mover.send('game:move', { code, ply, move: chosen.move });
      const moved = await other.next<Moved>('game:moved', (m) => m.ply === ply + 1);
      expect(moved.move).toEqual(chosen.move);
      const local = engine.play(mirror, moved.move, new Date());
      if (!local.ok) throw new Error(local.message);
      if (local.snapshot.result) {
        over = await other.next<Over>('game:over');
        expect(over.result).toEqual(local.snapshot.result);
      }
    }
    engine.close(mirror);
    expect(over?.result.reason).toMatch(/^(elimination|blocked)$/);
    expect(over?.ratingChanges).toBeDefined();
    const saved = (await t.http.get(`/api/games/${gameId}`).expect(200)).body as {
      summary: GameSummary;
    };
    expect(saved.summary).toMatchObject({ status: 'finished', result: over?.result });
  });

  describe('protocol', () => {
    let client: WsClient;

    beforeAll(async () => {
      client = await t.connect(await t.register('proto'));
    });

    it('answers ping with pong', async () => {
      client.send('ping', {});
      await expect(client.next('pong')).resolves.toEqual({});
    });

    it('refuses frames that are not {event, data} JSON (INVALID_MESSAGE)', async () => {
      client.sendRaw('not json');
      expect(await client.next('error')).toMatchObject({ code: 'INVALID_MESSAGE', event: null });
      client.sendRaw('{"data": {}}');
      expect(await client.next('error')).toMatchObject({ code: 'INVALID_MESSAGE', event: null });
      expect(await client.expectError('room:explode', {})).toMatchObject({
        code: 'INVALID_MESSAGE',
        event: 'room:explode',
      });
    });

    it('validates room options (INVALID_MESSAGE)', async () => {
      for (const data of [
        { color: 'green' },
        { rated: 'yes' },
        { timeControl: { initialSeconds: -1, incrementSeconds: 0 } },
        { timeControl: { initialSeconds: 60 } },
      ]) {
        expect((await client.expectError('room:create', data)).code).toBe('INVALID_MESSAGE');
      }
    });

    it('reports unknown rooms (ROOM_NOT_FOUND)', async () => {
      for (const event of ['room:join', 'room:rejoin', 'game:sync', 'game:resign']) {
        expect((await client.expectError(event, { code: 'ZZZZZZ' })).code).toBe('ROOM_NOT_FOUND');
      }
    });

    it('closes connections without a valid token with code 4401', async () => {
      for (const token of [undefined, 'invalid']) {
        const anonymous = await WsClient.connect(t.wsUrl, token);
        expect((await anonymous.closed).code).toBe(4401);
      }
    });
  });

  describe('waiting rooms', () => {
    it('hands the room to the other player when the host leaves', async () => {
      const [x, y] = [await t.register('host'), await t.register('guest')];
      const [cx, cy] = [await t.connect(x), await t.connect(y)];
      cx.send('room:create', {});
      const { room } = await cx.next<{ room: RoomView }>('room:updated');
      cy.send('room:join', { code: room.code });
      await cx.next('room:updated', (d: { room: RoomView }) => d.room.players.length === 2);
      cx.send('room:leave', { code: room.code });
      const left = await cy.next<{ room: RoomView }>(
        'room:updated',
        (d) => d.room.players.length === 1,
      );
      expect(left.room).toMatchObject({ hostId: y.user.id, status: 'waiting' });
      expect((await cx.expectError('room:ready', { code: room.code, ready: true })).code).toBe(
        'NOT_IN_ROOM',
      );
      cy.send('room:leave', { code: room.code });
      await cy.next('room:updated', (d: { room: RoomView }) => d.room.players.length === 0);
      expect((await cy.expectError('room:join', { code: room.code })).code).toBe('ROOM_NOT_FOUND');
    });
  });
});
