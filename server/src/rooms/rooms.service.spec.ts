import { RealtimeBus } from '../realtime/realtime-bus';
import { TransactionRunner } from '../realtime/transactions';
import { RoomsHarness } from '../testing/rooms-harness';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { RoomView } from './active-room';
import { Room } from './room.entity';

/** What the rooms do when an account is deleted. */
describe('RoomsService account deletion', () => {
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

  function savedRoom(code: string): Promise<Room | null> {
    return h.dataSource.getRepository(Room).findOneBy({ code });
  }

  async function rejoin(userId: string, code: string): Promise<RoomView> {
    const reply = await h.rooms.rejoin(userId, code);
    if (reply.event !== 'room:updated') throw new Error(`Unexpected ${reply.event}`);
    return reply.data.room;
  }

  it('resigns the game in progress', async () => {
    const { code, gameId } = await h.started(alice, bob);
    await h.rooms.leaveAll(bob.id);
    expect(h.received(alice.id, 'game:over').at(-1)).toMatchObject({
      code,
      gameId,
      result: { winner: 'white', reason: 'resignation' },
    });
    expect(await rejoin(alice.id, code)).toMatchObject({ status: 'finished', gameId });
  });

  it('gives up a seat in a waiting room, handing it over to the other player', async () => {
    const code = await h.room(alice, bob);
    await h.rooms.leaveAll(alice.id);
    const room = await rejoin(bob.id, code);
    expect(room.players.map((p) => p.user.id)).toEqual([bob.id]);
    expect(room.hostId).toBe(bob.id);
  });

  it('closes a waiting room left empty', async () => {
    const code = await h.room(alice);
    await h.rooms.leaveAll(alice.id);
    await expect(h.rooms.rejoin(alice.id, code)).rejects.toMatchObject({ code: 'ROOM_NOT_FOUND' });
    expect((await savedRoom(code))?.closedAt).toEqual(expect.any(Date));
  });

  it('closes the waiting rooms of its tournament matches, whose seats are fixed', async () => {
    const code = await h.app
      .get(TransactionRunner)
      .run('test', (tx) =>
        h.rooms.createForMatch(tx, 'f5b1b6c6-0000-4000-8000-000000000001', alice, bob),
      );
    await h.rooms.leaveAll(alice.id);
    await expect(h.rooms.rejoin(bob.id, code)).rejects.toMatchObject({ code: 'ROOM_NOT_FOUND' });
    const closed = h.sent.at(-1);
    expect(closed).toMatchObject({
      to: [alice.id, bob.id],
      event: 'room:updated',
      data: { room: { status: 'finished', gameId: null } },
    });
  });

  it('then shows the anonymous name and closes the connections of the account', async () => {
    const { code } = await h.started(alice, bob);
    await h.rooms.leaveAll(bob.id);
    const disconnected: string[] = [];
    h.app.get(RealtimeBus).onMessage((message) => {
      disconnected.push(...(message.disconnect ?? []));
    });
    const deleted = await h.app.get(UsersService).delete(bob.id);
    await h.rooms.accountDeleted(deleted);
    expect(disconnected).toEqual([bob.id]);
    const room = await rejoin(alice.id, code);
    const names = room.players.map((p) => p.user.username);
    expect(names).toEqual([alice.username, deleted.username]);
    expect(deleted.username).toMatch(/^deleted_/);
  });
});
