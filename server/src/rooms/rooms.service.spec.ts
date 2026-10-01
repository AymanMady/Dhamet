import { Repository } from 'typeorm';
import { WebSocket } from 'ws';
import { AppConfig, readSettings } from '../config/app.config';
import { EngineService } from '../engine/engine.service';
import { GamesService } from '../games/games.service';
import { User } from '../users/user.entity';
import { toUserView } from '../users/user.view';
import { UsersService } from '../users/users.service';
import { ActiveRoom } from './active-room';
import { ConnectionRegistry } from './connection-registry';
import { GameplayService } from './gameplay.service';
import { Room } from './room.entity';
import { RoomStore } from './room-store';
import { RoomsService } from './rooms.service';

function account(id: string, username = id): User {
  return Object.assign(new User(), {
    id,
    username,
    usernameKey: username,
    passwordHash: '',
    isGuest: false,
    avatar: null,
    rating: 1200,
    wins: 0,
    losses: 0,
    draws: 0,
    createdAt: new Date(0),
    deletedAt: null,
  });
}

/** What the rooms do when an account is deleted. */
describe('RoomsService account deletion', () => {
  const engine = new EngineService();
  const games = {
    start: jest.fn().mockResolvedValue(undefined),
    finish: jest.fn().mockResolvedValue(null),
  };
  const users = { findById: jest.fn().mockResolvedValue(null) };
  const rooms = { insert: jest.fn(), update: jest.fn() };
  const settings: AppConfig = readSettings({ DB_TYPE: 'sqljs' });
  let store: RoomStore;
  let connections: ConnectionRegistry;
  let gameplay: GameplayService;
  let service: RoomsService;

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
    service = new RoomsService(
      store,
      gameplay,
      connections,
      users as unknown as UsersService,
      settings,
    );
  });

  afterEach(() => {
    store.onModuleDestroy();
  });

  /** A room of [ids] (White first), hosted by the first one. */
  function room(ids: string[], tournamentMatchId: string | null = null): Promise<ActiveRoom> {
    return store.open({
      hostId: ids[0] ?? '',
      rated: false,
      timeControl: null,
      tournamentMatchId,
      players: ids.map((id, index) => ({
        user: toUserView(account(id)),
        color: index === 0 ? 'white' : 'black',
        ready: true,
        connected: true,
      })),
    });
  }

  async function started(ids: string[]): Promise<ActiveRoom> {
    const opened = await room(ids);
    await opened.run(() => gameplay.startInRoom(opened));
    return opened;
  }

  it('resigns the game in progress', async () => {
    const opened = await started(['alice', 'bob']);
    await service.leaveAll('bob');
    expect(opened.status).toBe('finished');
    expect(games.finish).toHaveBeenCalledWith(
      opened.game?.id,
      expect.objectContaining({ result: { winner: 'white', reason: 'resignation' } }),
    );
  });

  it('gives up a seat in a waiting room, handing it over to the other player', async () => {
    const opened = await room(['alice', 'bob']);
    await service.leaveAll('alice');
    expect(store.get(opened.code)).toBe(opened);
    expect(opened.players.map((p) => p.user.id)).toEqual(['bob']);
    expect(opened.hostId).toBe('bob');
  });

  it('closes a waiting room left empty', async () => {
    const opened = await room(['alice']);
    await service.leaveAll('alice');
    expect(() => store.get(opened.code)).toThrow(
      expect.objectContaining({ code: 'ROOM_NOT_FOUND' }),
    );
  });

  it('closes the waiting rooms of its tournament matches, whose seats are fixed', async () => {
    const opened = await room(['alice', 'bob'], 'match-1');
    await service.leaveAll('alice');
    expect(opened.status).toBe('finished');
    expect(() => store.get(opened.code)).toThrow(
      expect.objectContaining({ code: 'ROOM_NOT_FOUND' }),
    );
    expect(connections.broadcast).toHaveBeenCalledWith(['alice', 'bob'], 'room:updated', {
      room: expect.objectContaining({ status: 'finished', gameId: null }),
    });
  });

  it('then shows the anonymous name and closes the connections of the account', async () => {
    const opened = await started(['alice', 'bob']);
    await service.leaveAll('bob');
    const socket = { close: jest.fn() };
    connections.add(socket as unknown as WebSocket, 'bob');
    await service.accountDeleted(account('bob', 'deleted_ab12'));
    expect(opened.player('bob')?.user.username).toBe('deleted_ab12');
    expect(opened.player('alice')?.user.username).toBe('alice');
    expect(socket.close).toHaveBeenCalledWith(4401, 'Unauthenticated');
  });
});
