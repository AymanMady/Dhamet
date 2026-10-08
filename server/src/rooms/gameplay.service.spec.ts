import { MoveJson } from '../engine/engine.types';
import { Move } from '../games/move.entity';
import { RoomsHarness } from '../testing/rooms-harness';
import { User } from '../users/user.entity';
import { GameErrorCode } from './game-error';

const d4e5: MoveJson = { piece: 'w', from: 'd4', path: ['e5'], captured: [], promotes: false };
const f6xd4: MoveJson = { piece: 'b', from: 'f6', path: ['d4'], captured: ['e5'], promotes: false };

/** The checks of `game:move`, in the order of docs/multiplayer.md. */
describe('game:move validation', () => {
  let h: RoomsHarness;
  let alice: User;
  let bob: User;

  beforeAll(async () => {
    h = await RoomsHarness.start();
  });

  afterAll(async () => {
    await h.stop();
  });

  beforeEach(async () => {
    [alice, bob] = [await h.account('alice'), await h.account('bob')];
  });

  async function expectRefusal(promise: Promise<unknown>, code: GameErrorCode): Promise<void> {
    await expect(promise).rejects.toMatchObject({ code });
  }

  it('refuses an unknown room', async () => {
    await expectRefusal(h.rooms.move(alice.id, 'ZZZZZZ', 0, d4e5), 'ROOM_NOT_FOUND');
  });

  it('refuses a user who is not a member (NOT_IN_ROOM)', async () => {
    const { code } = await h.started(alice, bob);
    const mallory = await h.account('mallory');
    await expectRefusal(h.rooms.move(mallory.id, code, 0, d4e5), 'NOT_IN_ROOM');
  });

  it('refuses a move before the game starts (GAME_NOT_STARTED)', async () => {
    const code = await h.room(alice, bob);
    await expectRefusal(h.rooms.move(alice.id, code, 0, d4e5), 'GAME_NOT_STARTED');
  });

  it('refuses a move after the game ended (GAME_OVER)', async () => {
    const { code } = await h.started(alice, bob);
    await h.rooms.resign(bob.id, code);
    await expectRefusal(h.rooms.move(alice.id, code, 0, d4e5), 'GAME_OVER');
  });

  it('checks the turn before the ply (NOT_YOUR_TURN)', async () => {
    const { code } = await h.started(alice, bob);
    await expectRefusal(h.rooms.move(bob.id, code, 0, f6xd4), 'NOT_YOUR_TURN');
    await expectRefusal(h.rooms.move(bob.id, code, 7, f6xd4), 'NOT_YOUR_TURN');
  });

  it('checks the ply before legality (STALE_PLY)', async () => {
    const { code } = await h.started(alice, bob);
    await expectRefusal(h.rooms.move(alice.id, code, 1, d4e5), 'STALE_PLY');
    await expectRefusal(h.rooms.move(alice.id, code, 1, { ...d4e5, from: 'a1' }), 'STALE_PLY');
  });

  it('leaves legality to the engine (ILLEGAL_MOVE)', async () => {
    const { code } = await h.started(alice, bob);
    await expectRefusal(h.rooms.move(alice.id, code, 0, { ...d4e5, from: 'c4' }), 'ILLEGAL_MOVE');
    await expectRefusal(h.rooms.move(alice.id, code, 0, { nonsense: true }), 'ILLEGAL_MOVE');
  });

  it('plays, saves and broadcasts the engine copy of a legal move', async () => {
    const { code, gameId } = await h.started(alice, bob);
    // Extra fields sent by the client are not trusted nor forwarded.
    await h.rooms.move(alice.id, code, 0, { ...d4e5, notation: 'forged' });
    expect(h.received(bob.id, 'game:moved').at(-1)).toEqual({
      code,
      gameId,
      ply: 1,
      move: d4e5,
    });
    await h.rooms.move(bob.id, code, 1, f6xd4);
    const saved = await h.dataSource
      .getRepository(Move)
      .find({ where: { gameId }, order: { ply: 'ASC' } });
    expect(saved.map((m) => [m.ply, m.userId, m.moveJson])).toEqual([
      [1, alice.id, d4e5],
      [2, bob.id, f6xd4],
    ]);
  });
});
