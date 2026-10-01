import { DataSource } from 'typeorm';
import { GameResultJson } from '../src/engine/engine.types';
import { GameSummary } from '../src/games/games.service';
import { LeaderboardEntry } from '../src/ranking/ranking.service';
import { RoomView } from '../src/rooms/active-room';
import { TournamentPlayer } from '../src/tournaments/tournament-player.entity';
import { TournamentView } from '../src/tournaments/tournament.view';
import { Account, TestApp } from './support/test-app';
import { WsClient } from './support/ws-client';

/** The name given to a deleted account. */
const DELETED_NAME = /^deleted_[a-z0-9]{4,}$/;

interface Over {
  code: string;
  gameId: string;
  result: GameResultJson;
  ratingChanges?: Record<string, number>;
}

describe('Account deletion (DELETE /api/users/me)', () => {
  let t: TestApp;

  const auth = (account: Account): [string, string] => ['Authorization', `Bearer ${account.token}`];
  const deleteAccount = (account: Account) => t.http.delete('/api/users/me').set(...auth(account));

  beforeAll(async () => {
    t = await TestApp.start();
  });

  afterAll(async () => {
    await t.stop();
  });

  it('deletes the account: 204, then its token and password are refused', async () => {
    const account = await t.register('gone');
    const response = await deleteAccount(account).expect(204);
    expect(response.text).toBe('');
    await t.http
      .get('/api/users/me')
      .set(...auth(account))
      .expect(401);
    await deleteAccount(account).expect(401);
    await t.http
      .post('/api/auth/login')
      .send({ username: account.user.username, password: 'password123' })
      .expect(401);
    await t.http.get(`/api/users/${account.user.id}`).expect(404);
    await t.http.get(`/api/users/${account.user.id}/games`).expect(404);
  });

  it('requires a valid token: 401', async () => {
    await t.http.delete('/api/users/me').expect(401);
    await t.http.delete('/api/users/me').set('Authorization', 'Bearer not-a-jwt').expect(401);
  });

  it('deletes guest accounts too', async () => {
    const guest = await t.guest();
    await deleteAccount(guest).expect(204);
    await t.http.get(`/api/users/${guest.user.id}`).expect(404);
  });

  it('closes its WebSocket connections and refuses its token there: 4401', async () => {
    const account = await t.register('ws');
    const open = await t.connect(account);
    await deleteAccount(account).expect(204);
    expect(await open.closed).toEqual({ code: 4401, reason: 'Unauthenticated' });
    const again = await WsClient.connect(t.wsUrl, account.token);
    expect((await again.closed).code).toBe(4401);
  });

  it('frees the username, whatever its case', async () => {
    const account = await t.register('reuse');
    await deleteAccount(account).expect(204);
    const username = account.user.username.toUpperCase();
    const response = await t.http
      .post('/api/auth/register')
      .send({ username, password: 'another-password' })
      .expect(201);
    expect(response.body.user).toMatchObject({ username, rating: 1200, gamesPlayed: 0 });
    expect(response.body.user.id).not.toBe(account.user.id);
    await t.http
      .post('/api/auth/login')
      .send({ username: account.user.username, password: 'another-password' })
      .expect(200);
  });

  it('leaves the leaderboard', async () => {
    const account = await t.register('ranked');
    const ranked = async (): Promise<string[]> => {
      const response = await t.http.get('/api/leaderboard?limit=200').expect(200);
      return (response.body as LeaderboardEntry[]).map((entry) => entry.user.id);
    };
    expect(await ranked()).toContain(account.user.id);
    await deleteAccount(account).expect(204);
    expect(await ranked()).not.toContain(account.user.id);
  });

  it('keeps the games of its opponents, under an anonymous name', async () => {
    const [white, black] = [await t.register('leaver'), await t.register('stayer')];
    const [w, b] = [await t.connect(white), await t.connect(black)];
    const { code, gameId } = await t.startGame(w, b, { rated: true });
    w.send('game:resign', { code });
    await b.next('game:over');
    await deleteAccount(white).expect(204);

    // The finished room, open for the grace period (1 s here), shows the new name.
    b.send('room:rejoin', { code });
    const { room } = await b.next<{ room: RoomView }>('room:updated');
    expect(room.players.find((p) => p.color === 'white')?.user.username).toMatch(DELETED_NAME);

    const response = await t.http.get(`/api/games/${gameId}`).expect(200);
    const { summary } = response.body as { summary: GameSummary };
    expect(summary).toMatchObject({
      status: 'finished',
      result: { winner: 'black', reason: 'resignation' },
      white: { id: white.user.id, username: expect.stringMatching(DELETED_NAME) },
      black: { id: black.user.id, username: black.user.username, rating: 1216 },
    });
    expect(JSON.stringify(response.body)).not.toContain(white.user.username);
    const games = await t.http.get(`/api/users/${black.user.id}/games`).expect(200);
    expect((games.body as GameSummary[]).map((game) => game.id)).toContain(gameId);
  });

  it('resigns its game in progress: the opponent wins', async () => {
    const [white, black] = [await t.register('w'), await t.register('quitter')];
    const [w, b] = [await t.connect(white), await t.connect(black)];
    const { code, gameId } = await t.startGame(w, b, { rated: true });
    await deleteAccount(black).expect(204);
    expect(await w.next<Over>('game:over')).toEqual({
      code,
      gameId,
      result: { winner: 'white', reason: 'resignation' },
      ratingChanges: { [white.user.id]: 16, [black.user.id]: -16 },
    });
    expect((await b.closed).code).toBe(4401);
    const response = await t.http.get(`/api/games/${gameId}`).expect(200);
    expect((response.body as { summary: GameSummary }).summary).toMatchObject({
      status: 'finished',
      black: { id: black.user.id, username: expect.stringMatching(DELETED_NAME) },
    });
  });

  it('hands its waiting room over to the other player', async () => {
    const [host, guest] = [await t.register('host'), await t.register('guest')];
    const [h, g] = [await t.connect(host), await t.connect(guest)];
    h.send('room:create', {});
    const { room } = await h.next<{ room: RoomView }>('room:updated');
    g.send('room:join', { code: room.code });
    await g.next('room:updated', (d: { room: RoomView }) => d.room.players.length === 2);
    await deleteAccount(host).expect(204);
    const left = await g.next<{ room: RoomView }>(
      'room:updated',
      (d) => d.room.players.length === 1,
    );
    expect(left.room).toMatchObject({ code: room.code, status: 'waiting', hostId: guest.user.id });
  });

  it('closes a waiting room it was alone in', async () => {
    const host = await t.register('alone');
    const h = await t.connect(host);
    h.send('room:create', {});
    const { room } = await h.next<{ room: RoomView }>('room:updated');
    await deleteAccount(host).expect(204);
    const other = await t.connect(await t.register('late'));
    expect((await other.expectError('room:join', { code: room.code })).code).toBe('ROOM_NOT_FOUND');
  });

  describe('tournaments', () => {
    async function create(creator: Account, maxPlayers: number): Promise<TournamentView> {
      const response = await t.http
        .post('/api/tournaments')
        .set(...auth(creator))
        .send({ name: 'Open', format: 'roundRobin', maxPlayers })
        .expect(201);
      return response.body as TournamentView;
    }

    async function join(player: Account, id: string): Promise<void> {
      await t.http
        .post(`/api/tournaments/${id}/join`)
        .set(...auth(player))
        .expect(200);
    }

    async function view(id: string): Promise<TournamentView> {
      return (await t.http.get(`/api/tournaments/${id}`).expect(200)).body as TournamentView;
    }

    /** [userId, seed] of each registration, by seed. */
    async function seeds(id: string): Promise<[string, number][]> {
      const players = await t.app
        .get(DataSource)
        .getRepository(TournamentPlayer)
        .find({ where: { tournamentId: id }, order: { seed: 'ASC' } });
      return players.map((player) => [player.userId, player.seed]);
    }

    it('withdraws its registrations to tournaments not started yet', async () => {
      const organiser = await t.register('org');
      const [first, leaver, third] = [
        await t.register('p'),
        await t.register('p'),
        await t.register('p'),
      ];
      const { id } = await create(organiser, 4);
      for (const player of [first, leaver, third]) await join(player, id);
      await deleteAccount(leaver).expect(204);
      expect((await view(id)).players.map((p) => p.user.id)).toEqual([
        first.user.id,
        third.user.id,
      ]);
      // The pairing order stays the registration order, without a gap.
      const late = await t.register('p');
      await join(late, id);
      expect(await seeds(id)).toEqual([
        [first.user.id, 1],
        [third.user.id, 2],
        [late.user.id, 3],
      ]);
    });

    it('cancels the tournaments not started yet that it created', async () => {
      const organiser = await t.register('org');
      const player = await t.register('p');
      const { id } = await create(organiser, 4);
      await join(player, id);
      await deleteAccount(organiser).expect(204);
      await t.http.get(`/api/tournaments/${id}`).expect(404);
    });

    it('loses its remaining matches in a running tournament', async () => {
      const organiser = await t.register('org');
      const [a, b, leaver] = [await t.register('a'), await t.register('b'), await t.register('x')];
      const { id } = await create(organiser, 3);
      for (const player of [a, b, leaver]) await join(player, id);
      await t.http
        .post(`/api/tournaments/${id}/start`)
        .set(...auth(organiser))
        .expect(200);
      const matches = (await view(id)).rounds.flatMap((round) => round.matches);
      const between = (x: Account, y: Account) => {
        const found = matches.find((m) =>
          [m.white.id, m.black.id].every((player) => [x.user.id, y.user.id].includes(player)),
        );
        if (!found) throw new Error(`No match between ${x.user.username} and ${y.user.username}`);
        return found;
      };
      const [played, waiting, remaining] = [between(a, leaver), between(b, leaver), between(a, b)];

      // The leaver is playing against A; B waits in the room of its match.
      const clients = new Map<string, WsClient>();
      for (const player of [a, b, leaver]) clients.set(player.user.id, await t.connect(player));
      const client = (player: Account): WsClient => clients.get(player.user.id) as WsClient;
      for (const player of [a, leaver]) {
        client(player).send('room:join', { code: played.roomCode });
        await client(player).next('room:updated');
        client(player).send('room:ready', { code: played.roomCode, ready: true });
      }
      await client(a).next('game:started');
      client(b).send('room:join', { code: waiting.roomCode });
      await client(b).next('room:updated');

      await deleteAccount(leaver).expect(204);
      const aColor = played.white.id === a.user.id ? 'white' : 'black';
      expect(await client(a).next<Over>('game:over')).toMatchObject({
        code: played.roomCode,
        result: { winner: aColor, reason: 'resignation' },
      });
      const closed = await client(b).next<{ room: RoomView }>(
        'room:updated',
        (d) => d.room.status === 'finished',
      );
      expect(closed.room).toMatchObject({ code: waiting.roomCode, gameId: null });
      expect((await client(b).expectError('room:join', { code: waiting.roomCode })).code).toBe(
        'ROOM_NOT_FOUND',
      );

      let tournament = await view(id);
      const match = (matchId: string) =>
        tournament.rounds.flatMap((round) => round.matches).find((m) => m.id === matchId);
      expect(match(played.id)).toMatchObject({
        gameId: expect.any(String),
        result: { winner: aColor, reason: 'resignation' },
      });
      // A match never played is lost without a game.
      expect(match(waiting.id)).toMatchObject({
        gameId: null,
        result: {
          winner: waiting.white.id === b.user.id ? 'white' : 'black',
          reason: 'resignation',
        },
      });
      expect(match(remaining.id)).toMatchObject({ gameId: null, result: null });
      expect(tournament.status).toBe('running');
      expect(tournament.players.map((p) => [p.user.id, p.score])).toEqual([
        [a.user.id, 1],
        [b.user.id, 1],
        [leaver.user.id, 0],
      ]);
      expect(tournament.players[2]?.user.username).toMatch(DELETED_NAME);

      // The last match still finishes the tournament.
      const [white, black] =
        remaining.white.id === a.user.id ? [client(a), client(b)] : [client(b), client(a)];
      for (const player of [white, black]) {
        player.send('room:join', { code: remaining.roomCode });
        await player.next('room:updated');
        player.send('room:ready', { code: remaining.roomCode, ready: true });
      }
      await white.next('game:started');
      white.send('game:resign', { code: remaining.roomCode });
      await black.next('game:over');
      tournament = await view(id);
      expect(tournament.status).toBe('finished');
      expect(match(remaining.id)?.result).toEqual({ winner: 'black', reason: 'resignation' });
    });
  });
});
