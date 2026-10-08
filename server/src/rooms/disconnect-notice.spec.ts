import { RoomsHarness } from '../testing/rooms-harness';
import { User } from '../users/user.entity';

const NOTICE_MS = 300;

const pause = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

/**
 * Vercel closes every WebSocket at the end of the function's maximum
 * duration and the app reconnects at once: the opponent only hears of a
 * disconnection that lasts (DISCONNECT_NOTICE_SECONDS).
 */
describe('Disconnection notice', () => {
  let h: RoomsHarness;
  let alice: User;
  let bob: User;

  beforeAll(async () => {
    h = await RoomsHarness.start({ noticeSeconds: NOTICE_MS / 1000 });
  });

  afterAll(async () => {
    await h.stop();
  });

  beforeEach(async () => {
    [alice, bob] = [await h.account('alice'), await h.account('bob')];
  });

  it('says nothing of a connection replaced in time', async () => {
    const { code } = await h.started(alice, bob);
    const before = h.sent.length;
    await h.rooms.handleOffline(bob.id, Date.now());
    await h.rooms.rejoin(bob.id, code);
    await pause(NOTICE_MS + 50);
    await h.rooms.settle(code);
    expect(h.sent.slice(before).filter((d) => d.to.includes(alice.id))).toEqual([]);
  });

  it('tells the opponent once the notice delay has passed, with the grace left', async () => {
    const { code } = await h.started(alice, bob);
    await h.rooms.handleOffline(bob.id, Date.now());
    await h.rooms.settle(code);
    expect(h.received(alice.id, 'player:disconnected')).toEqual([]);

    await pause(NOTICE_MS + 50);
    await h.rooms.settle(code);
    expect(h.received(alice.id, 'player:disconnected')).toEqual([
      { code, userId: bob.id, graceSeconds: 60 },
    ]);

    await h.rooms.rejoin(bob.id, code);
    expect(h.received(alice.id, 'player:reconnected')).toEqual([{ code, userId: bob.id }]);
  });

  it('applies overdue deadlines when sweeping', async () => {
    const { code } = await h.started(alice, bob);
    await h.rooms.handleOffline(bob.id, Date.now());
    await pause(NOTICE_MS + 50);
    expect(await h.rooms.sweep()).toBeGreaterThanOrEqual(1);
    expect(h.received(alice.id, 'player:disconnected')).toEqual([
      expect.objectContaining({ code, userId: bob.id }),
    ]);
  });
});
