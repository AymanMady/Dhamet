import { Repository } from 'typeorm';
import { AppConfig, readSettings } from '../config/app.config';
import { EngineService } from '../engine/engine.service';
import { MoveJson } from '../engine/engine.types';
import { GamesService } from '../games/games.service';
import { UserView } from '../users/user.view';
import { UsersService } from '../users/users.service';
import { ActiveRoom } from './active-room';
import { ConnectionRegistry } from './connection-registry';
import { GameErrorCode } from './game-error';
import { GameplayService } from './gameplay.service';
import { Room } from './room.entity';
import { RoomStore } from './room-store';

function user(id: string): UserView {
  return {
    id,
    username: id,
    isGuest: false,
    rating: 1200,
    wins: 0,
    losses: 0,
    draws: 0,
    gamesPlayed: 0,
    createdAt: new Date(0).toISOString(),
  };
}

const d4e5: MoveJson = { piece: 'w', from: 'd4', path: ['e5'], captured: [], promotes: false };
const f6xd4: MoveJson = { piece: 'b', from: 'f6', path: ['d4'], captured: ['e5'], promotes: false };

/** The checks of `game:move`, in the order of docs/multiplayer.md. */
describe('GameplayService move validation', () => {
  const engine = new EngineService();
  const games = {
    start: jest.fn().mockResolvedValue(undefined),
    recordMove: jest.fn().mockResolvedValue(undefined),
    finish: jest.fn().mockResolvedValue(null),
  };
  const users = { findById: jest.fn().mockResolvedValue(null) };
  const rooms = { insert: jest.fn(), update: jest.fn() };
  const settings: AppConfig = readSettings({ DB_TYPE: 'sqljs' });
  let store: RoomStore;
  let connections: ConnectionRegistry;
  let gameplay: GameplayService;

  beforeEach(() => {
    jest.clearAllMocks();
    store = new RoomStore(rooms as unknown as Repository<Room>);
    connections = new ConnectionRegistry();
    jest.spyOn(connections, 'broadcast');
    gameplay = new GameplayService(
      engine,
      games as unknown as GamesService,
      users as unknown as UsersService,
      store,
      connections,
      settings,
    );
  });

  afterEach(() => {
    store.onModuleDestroy();
  });

  async function room(started = true): Promise<ActiveRoom> {
    const opened = await store.open({
      hostId: 'alice',
      rated: false,
      timeControl: null,
      tournamentMatchId: null,
      players: [
        { user: user('alice'), color: 'white', ready: true, connected: true },
        { user: user('bob'), color: 'black', ready: true, connected: true },
      ],
    });
    if (started) await opened.run(() => gameplay.startInRoom(opened));
    return opened;
  }

  async function expectRefusal(promise: Promise<unknown>, code: GameErrorCode): Promise<void> {
    await expect(promise).rejects.toMatchObject({ code });
    expect(games.recordMove).not.toHaveBeenCalled();
  }

  it('refuses an unknown room', async () => {
    await expectRefusal(gameplay.move('alice', 'ZZZZZZ', 0, d4e5), 'ROOM_NOT_FOUND');
  });

  it('refuses a user who is not a member (NOT_IN_ROOM)', async () => {
    const { code } = await room();
    await expectRefusal(gameplay.move('mallory', code, 0, d4e5), 'NOT_IN_ROOM');
  });

  it('refuses a move before the game starts (GAME_NOT_STARTED)', async () => {
    const { code } = await room(false);
    await expectRefusal(gameplay.move('alice', code, 0, d4e5), 'GAME_NOT_STARTED');
  });

  it('refuses a move after the game ended (GAME_OVER)', async () => {
    const { code } = await room();
    await gameplay.resign('bob', code);
    await expectRefusal(gameplay.move('alice', code, 0, d4e5), 'GAME_OVER');
  });

  it('checks the turn before the ply (NOT_YOUR_TURN)', async () => {
    const { code } = await room();
    await expectRefusal(gameplay.move('bob', code, 0, f6xd4), 'NOT_YOUR_TURN');
    await expectRefusal(gameplay.move('bob', code, 7, f6xd4), 'NOT_YOUR_TURN');
  });

  it('checks the ply before legality (STALE_PLY)', async () => {
    const { code } = await room();
    await expectRefusal(gameplay.move('alice', code, 1, d4e5), 'STALE_PLY');
    await expectRefusal(gameplay.move('alice', code, 1, { ...d4e5, from: 'a1' }), 'STALE_PLY');
  });

  it('leaves legality to the engine (ILLEGAL_MOVE)', async () => {
    const { code } = await room();
    await expectRefusal(gameplay.move('alice', code, 0, { ...d4e5, from: 'c4' }), 'ILLEGAL_MOVE');
    await expectRefusal(gameplay.move('alice', code, 0, { nonsense: true }), 'ILLEGAL_MOVE');
  });

  it('plays, saves and broadcasts the engine copy of a legal move', async () => {
    const opened = await room();
    // Extra fields sent by the client are not trusted nor forwarded.
    await gameplay.move('alice', opened.code, 0, { ...d4e5, notation: 'forged' });
    expect(games.recordMove).toHaveBeenCalledWith(
      expect.objectContaining({ ply: 1, userId: 'alice', move: d4e5 }),
    );
    expect(connections.broadcast).toHaveBeenCalledWith(['alice', 'bob'], 'game:moved', {
      code: opened.code,
      gameId: opened.game?.id,
      ply: 1,
      move: d4e5,
    });
    await gameplay.move('bob', opened.code, 1, f6xd4);
    expect(opened.game?.snapshot.plyCount).toBe(2);
  });
});
