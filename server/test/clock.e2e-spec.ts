import { GameResultJson } from '../src/engine/engine.types';
import { TestApp } from './support/test-app';

describe('Clocks (optional timeControl)', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await TestApp.start();
  });

  afterAll(async () => {
    await t.stop();
  });

  it('ends the game on time when the side to move runs out', async () => {
    const [white, black] = [await t.register('w'), await t.register('b')];
    const [w, b] = [await t.connect(white), await t.connect(black)];
    const timeControl = { initialSeconds: 2, incrementSeconds: 1 };
    const { code, gameId, game } = await t.startGame(w, b, { timeControl });

    w.send('game:move', { code, ply: 0, move: t.legalMove(game, 'd4-e5') });
    const moved = await b.next<{ clocks: { white: number; black: number } }>('game:moved');
    // White used a little time and got the 1 s increment; Black's clock has not run.
    expect(moved.clocks.white).toBeGreaterThan(2000);
    expect(moved.clocks.white).toBeLessThanOrEqual(3000);
    expect(moved.clocks.black).toBe(2000);

    b.send('game:sync', { code });
    const sync = await b.next<{ clocks: { white: number; black: number } }>('game:sync');
    expect(sync.clocks.black).toBeLessThanOrEqual(2000);

    // Black does not move: the server flags Black.
    const over = await w.next<{ result: GameResultJson; gameId: string }>(
      'game:over',
      () => true,
      6000,
    );
    expect(over).toMatchObject({ code, gameId, result: { winner: 'white', reason: 'timeout' } });
    await b.next('game:over');

    const saved = await t.http.get(`/api/games/${gameId}`).expect(200);
    expect(saved.body.summary).toMatchObject({
      status: 'finished',
      result: { winner: 'white', reason: 'timeout' },
      plyCount: 1,
    });
    expect(saved.body.game.declaredResult).toEqual({ winner: 'white', reason: 'timeout' });
  });

  it('has no clock without a timeControl', async () => {
    const [white, black] = [await t.register('w'), await t.register('b')];
    const [w, b] = [await t.connect(white), await t.connect(black)];
    const { code, game } = await t.startGame(w, b);
    w.send('game:move', { code, ply: 0, move: t.legalMove(game, 'd4-e5') });
    expect(await b.next('game:moved')).not.toHaveProperty('clocks');
  });
});
