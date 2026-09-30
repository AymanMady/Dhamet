import { GameResultJson } from '../src/engine/engine.types';
import { RoomView } from '../src/rooms/active-room';
import { TournamentView } from '../src/tournaments/tournament.view';
import { Account, TestApp } from './support/test-app';
import { WsClient } from './support/ws-client';

describe('Tournaments (round robin)', () => {
  let t: TestApp;
  let organiser: Account;
  let players: Account[];
  let tournament: TournamentView;

  const auth = (account: Account): [string, string] => ['Authorization', `Bearer ${account.token}`];

  beforeAll(async () => {
    t = await TestApp.start();
    organiser = await t.register('org');
    players = [await t.register('p'), await t.register('p'), await t.register('p')];
  });

  afterAll(async () => {
    await t.stop();
  });

  it('reserves single elimination for later: 400', async () => {
    const response = await t.http
      .post('/api/tournaments')
      .set(...auth(organiser))
      .send({ name: 'Cup', format: 'singleElimination', maxPlayers: 4 })
      .expect(400);
    expect(response.body.message).toMatch(/not implemented yet/);
  });

  it('validates the request', async () => {
    await t.http
      .post('/api/tournaments')
      .send({ name: 'x', format: 'roundRobin', maxPlayers: 4 })
      .expect(401);
    for (const body of [
      { name: '', format: 'roundRobin', maxPlayers: 4 },
      { name: 'Open', format: 'swiss', maxPlayers: 4 },
      { name: 'Open', format: 'roundRobin', maxPlayers: 1 },
    ]) {
      await t.http
        .post('/api/tournaments')
        .set(...auth(organiser))
        .send(body)
        .expect(400);
    }
  });

  it('creates a round robin: 201', async () => {
    const response = await t.http
      .post('/api/tournaments')
      .set(...auth(organiser))
      .send({ name: 'Nouakchott Open', format: 'roundRobin', maxPlayers: 3 })
      .expect(201);
    tournament = response.body as TournamentView;
    expect(tournament).toEqual({
      id: expect.any(String),
      name: 'Nouakchott Open',
      format: 'roundRobin',
      status: 'registering',
      maxPlayers: 3,
      createdBy: organiser.user,
      players: [],
      rounds: [],
      createdAt: expect.any(String),
    });
    const list = await t.http.get('/api/tournaments').expect(200);
    expect((list.body as TournamentView[]).map((x) => x.id)).toContain(tournament.id);
  });

  it('registers players up to maxPlayers', async () => {
    for (const player of players) {
      await t.http
        .post(`/api/tournaments/${tournament.id}/join`)
        .set(...auth(player))
        .expect(200);
    }
    await t.http
      .post(`/api/tournaments/${tournament.id}/join`)
      .set(...auth(players[0] as Account))
      .expect(200);
    await t.http
      .post(`/api/tournaments/${tournament.id}/join`)
      .set(...auth(organiser))
      .expect(400);
    const response = await t.http.get(`/api/tournaments/${tournament.id}`).expect(200);
    expect((response.body as TournamentView).players).toEqual(
      players.map((p) => ({ user: p.user, score: 0 })),
    );
  });

  it('lets only the creator start it: 403', async () => {
    await t.http
      .post(`/api/tournaments/${tournament.id}/start`)
      .set(...auth(players[0] as Account))
      .expect(403);
  });

  it('starts: every pair meets once, each match in a private rated room', async () => {
    const response = await t.http
      .post(`/api/tournaments/${tournament.id}/start`)
      .set(...auth(organiser))
      .expect(200);
    tournament = response.body as TournamentView;
    expect(tournament.status).toBe('running');
    expect(tournament.rounds.map((round) => round.number)).toEqual([1, 2, 3]);
    const matches = tournament.rounds.flatMap((round) => round.matches);
    expect(matches).toHaveLength(3);
    const pairs = matches.map((m) => [m.white.id, m.black.id].sort().join('/'));
    expect(new Set(pairs).size).toBe(3);
    for (const match of matches) {
      expect(match).toMatchObject({
        roomCode: expect.stringMatching(/^[A-Z2-9]{6}$/),
        gameId: null,
        result: null,
      });
    }
    await t.http
      .post(`/api/tournaments/${tournament.id}/start`)
      .set(...auth(organiser))
      .expect(400);
  });

  it('refuses registrations once started', async () => {
    const late = await t.register('late');
    await t.http
      .post(`/api/tournaments/${tournament.id}/join`)
      .set(...auth(late))
      .expect(400);
  });

  /** Both players enter the match room; White resigns. */
  async function playMatch(index: number): Promise<{ result: GameResultJson; blackId: string }> {
    const match = tournament.rounds.flatMap((round) => round.matches)[index];
    if (!match) throw new Error(`No match ${index}`);
    const account = (id: string): Account => players.find((p) => p.user.id === id) as Account;
    const w: WsClient = await t.connect(account(match.white.id));
    const b: WsClient = await t.connect(account(match.black.id));
    w.send('room:join', { code: match.roomCode });
    const { room } = await w.next<{ room: RoomView }>('room:updated');
    expect(room).toMatchObject({ rated: true, status: 'waiting' });
    expect(room.players.map((p) => p.user.id)).toEqual([match.white.id, match.black.id]);
    b.send('room:join', { code: match.roomCode });
    await b.next('room:updated');
    w.send('room:ready', { code: match.roomCode, ready: true });
    b.send('room:ready', { code: match.roomCode, ready: true });
    await w.next('game:started');
    w.send('game:resign', { code: match.roomCode });
    const over = await b.next<{ result: GameResultJson; ratingChanges?: object }>('game:over');
    expect(over.ratingChanges).toBeDefined();
    await Promise.all([w.close(), b.close()]);
    return { result: over.result, blackId: match.black.id };
  }

  it('records a finished match and updates the standings', async () => {
    const { result, blackId } = await playMatch(0);
    expect(result).toEqual({ winner: 'black', reason: 'resignation' });
    const response = await t.http.get(`/api/tournaments/${tournament.id}`).expect(200);
    const view = response.body as TournamentView;
    const [first] = view.rounds;
    expect(first?.matches[0]).toMatchObject({ result, gameId: expect.any(String) });
    expect(view.players[0]).toMatchObject({ user: { id: blackId }, score: 1 });
    expect(view.players.slice(1).map((p) => p.score)).toEqual([0, 0]);
    expect(view.status).toBe('running');
  });

  it('finishes once every match has a result', async () => {
    await playMatch(1);
    await playMatch(2);
    const response = await t.http.get(`/api/tournaments/${tournament.id}`).expect(200);
    const view = response.body as TournamentView;
    expect(view.status).toBe('finished');
    expect(view.players.reduce((sum, p) => sum + p.score, 0)).toBe(3);
    const scores = view.players.map((p) => p.score);
    expect(scores).toEqual([...scores].sort((x, y) => y - x));
  });
});
