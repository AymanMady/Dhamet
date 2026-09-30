import { EngineError, EngineService } from './engine.service';
import { LegalMove, MoveJson } from './engine.types';

/**
 * Parity with the Dart engine (packages/dhamet_engine/test): the server
 * must accept and refuse exactly what the engine does.
 */
describe('EngineService (Dart engine compiled to JavaScript)', () => {
  const engine = new EngineService();
  let next = 0;
  const open: string[] = [];

  function newGame(): string {
    const id = `engine-spec-${next++}`;
    engine.create(id);
    open.push(id);
    return id;
  }

  /** The legal move written [notation], full (`e5xc5xa5`) or abbreviated (`e5xa5`). */
  function legal(id: string, notation: string): LegalMove {
    const squares = notation.split(/[x-]/);
    const matches = engine
      .legalMoves(id)
      .filter(
        (candidate) =>
          candidate.notation === notation ||
          (squares.length === 2 &&
            candidate.move.from === squares[0] &&
            candidate.move.path.at(-1) === squares[1] &&
            candidate.move.captured.length > 0 === notation.includes('x')),
      );
    if (matches.length !== 1) throw new Error(`${notation} matches ${matches.length} moves`);
    return matches[0] as LegalMove;
  }

  const openingSequence = [
    'd4-e5', 'f6xd4', 'c3xe5', 'a5xc3', 'b2xd4',
    'c5xc3', 'e5xa5', 'c3xe5', 'f5xd5', 'd6xd4',
  ]; // prettier-ignore

  afterAll(() => {
    for (const id of open) engine.close(id);
  });

  it('starts from the traditional position, White to move', () => {
    const snapshot = engine.create('engine-spec-start');
    open.push('engine-spec-start');
    expect(snapshot).toMatchObject({
      currentPlayer: 'white',
      plyCount: 0,
      result: null,
      pieceCounts: { white: 40, black: 40 },
    });
    expect(snapshot.game).toMatchObject({
      format: 'dhamet.game',
      version: 1,
      declaredResult: null,
    });
    expect(snapshot.game).toMatchObject({ undoPolicy: { enabled: false, maxDepth: null } });
  });

  it('has exactly three first moves: d4-e5, e4-e5, f4-e5', () => {
    const moves = engine.legalMoves(newGame());
    expect(moves.map((m) => m.notation).sort()).toEqual(['d4-e5', 'e4-e5', 'f4-e5']);
    for (const { move } of moves) {
      expect(move).toMatchObject({ piece: 'w', path: ['e5'], captured: [], promotes: false });
    }
  });

  it('accepts the traditional opening move by move, then gives White three captures', () => {
    const id = newGame();
    openingSequence.forEach((notation, index) => {
      const { move } = legal(id, notation);
      const outcome = engine.play(id, move, new Date());
      if (!outcome.ok) throw new Error(`${notation}: ${outcome.message}`);
      expect(outcome.move).toEqual(move);
      expect(outcome.snapshot.plyCount).toBe(index + 1);
      expect(outcome.snapshot.currentPlayer).toBe(index % 2 === 0 ? 'black' : 'white');
      expect(outcome.snapshot.result).toBeNull();
    });
    expect(engine.snapshot(id).pieceCounts).toEqual({ white: 35, black: 35 });
    const replies = engine.legalMoves(id);
    expect(replies.map((m) => m.notation).sort()).toEqual(['d3xd5', 'e3xc5', 'e4xc4']);
    for (const { move } of replies) expect(move.captured).toEqual(['d4']);
  });

  it('forces the only capture after d4-e5', () => {
    const id = newGame();
    engine.play(id, legal(id, 'd4-e5').move, new Date());
    expect(engine.legalMoves(id).map((m) => m.notation)).toEqual(['f6xd4']);
  });

  describe('refuses illegal moves without changing the game', () => {
    const quiet = (from: string, to: string, piece: MoveJson['piece'] = 'w'): MoveJson => ({
      piece,
      from,
      path: [to],
      captured: [],
      promotes: false,
    });

    it.each([
      ['a move to an occupied point', quiet('d3', 'd4')],
      ['a move of the opponent', quiet('e6', 'e5', 'b')],
      ['a move from an empty point', quiet('e5', 'e6')],
      ['a capture that does not exist', { ...quiet('c3', 'e5'), captured: ['d4'] }],
      ['a false promotion', { ...quiet('d4', 'e5'), promotes: true }],
    ])('%s', (_label, move) => {
      const id = newGame();
      const outcome = engine.play(id, move, new Date());
      expect(outcome).toMatchObject({ ok: false, code: 'ILLEGAL_MOVE' });
      expect(engine.snapshot(id).plyCount).toBe(0);
    });

    it('a quiet move when a capture is mandatory', () => {
      const id = newGame();
      engine.play(id, legal(id, 'd4-e5').move, new Date());
      const outcome = engine.play(id, quiet('e6', 'd5', 'b'), new Date());
      expect(outcome).toMatchObject({ ok: false, code: 'ILLEGAL_MOVE' });
    });

    it.each([
      ['not an object', 'd4-e5'],
      ['without a path', { piece: 'w', from: 'd4', path: [] }],
      ['off the board', { piece: 'w', from: 'd4', path: ['z9'] }],
      ['with an unknown piece', { piece: 'x', from: 'd4', path: ['e5'] }],
    ])('malformed: %s', (_label, move) => {
      const id = newGame();
      expect(engine.play(id, move, new Date())).toMatchObject({ ok: false, code: 'ILLEGAL_MOVE' });
    });
  });

  it('ends the game on resignation, for the opponent', () => {
    const id = newGame();
    const snapshot = engine.resign(id, 'white');
    expect(snapshot.result).toEqual({ winner: 'black', reason: 'resignation' });
    expect(snapshot.game.declaredResult).toEqual({ winner: 'black', reason: 'resignation' });
    expect(engine.legalMoves(id)).toEqual([]);
    expect(engine.play(id, legal(newGame(), 'd4-e5').move, new Date())).toMatchObject({
      ok: false,
      code: 'GAME_OVER',
    });
    expect(() => engine.resign(id, 'black')).toThrow(EngineError);
  });

  it('ends the game on time', () => {
    const id = newGame();
    engine.play(id, legal(id, 'e4-e5').move, new Date());
    expect(engine.loseOnTime(id, 'black').result).toEqual({ winner: 'white', reason: 'timeout' });
  });

  it('saves and reloads a game exactly (JSON round trip)', () => {
    const id = newGame();
    const playedAt = new Date('2026-09-30T10:00:00.000Z');
    for (const notation of openingSequence) engine.play(id, legal(id, notation).move, playedAt);
    const saved = engine.snapshot(id);
    const json = JSON.parse(JSON.stringify(saved.game)) as typeof saved.game;

    const copy = `${id}-copy`;
    open.push(copy);
    const loaded = engine.load(copy, json);
    expect(loaded).toEqual(saved);
    expect(engine.legalMoves(copy)).toEqual(engine.legalMoves(id));
    expect(JSON.stringify(loaded.game)).toContain('"timestamp":"2026-09-30T10:00:00.000Z"');
  });

  it('refuses a saved game whose moves do not replay', () => {
    const id = newGame();
    engine.play(id, legal(id, 'd4-e5').move, new Date());
    const tampered = JSON.parse(
      JSON.stringify(engine.snapshot(id).game).replace('"from":"d4"', '"from":"c4"'),
    ) as ReturnType<EngineService['snapshot']>['game'];
    expect(() => engine.load('engine-spec-tampered', tampered)).toThrow(/INVALID_JSON/);
  });

  it('refuses unknown and duplicate ids', () => {
    expect(() => engine.snapshot('engine-spec-unknown')).toThrow(/UNKNOWN_GAME/);
    const id = newGame();
    expect(() => engine.create(id)).toThrow(/GAME_EXISTS/);
  });

  it('forgets closed games', () => {
    const before = engine.openGames;
    const id = `engine-spec-${next++}`;
    engine.create(id);
    expect(engine.openGames).toBe(before + 1);
    engine.close(id);
    expect(engine.openGames).toBe(before);
  });
});
