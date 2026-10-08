import { GameClock } from './game-clock';

describe('GameClock', () => {
  const start = 1_000_000;

  it('runs only the clock of the side to move', () => {
    const clock = new GameClock({ initialSeconds: 60, incrementSeconds: 0 }, 'white', start);
    expect(clock.read(start + 1500)).toEqual({ white: 58_500, black: 60_000 });
    clock.press(start + 2000);
    expect(clock.read(start + 5000)).toEqual({ white: 58_000, black: 57_000 });
  });

  it('adds the increment to the side that moved', () => {
    const clock = new GameClock({ initialSeconds: 10, incrementSeconds: 2 }, 'white', start);
    clock.press(start + 3000);
    expect(clock.read(start + 3000)).toEqual({ white: 9000, black: 10_000 });
  });

  it('flags the side to move at zero', () => {
    const clock = new GameClock({ initialSeconds: 1, incrementSeconds: 0 }, 'black', start);
    expect(clock.hasFlagged(start + 999)).toBe(false);
    expect(clock.msUntilFlag(start + 400)).toBe(600);
    expect(clock.hasFlagged(start + 1000)).toBe(true);
    expect(clock.read(start + 5000)).toEqual({ white: 1000, black: 0 });
  });

  it('freezes when stopped', () => {
    const clock = new GameClock({ initialSeconds: 5, incrementSeconds: 0 }, 'white', start);
    clock.stop(start + 1000);
    expect(clock.read(start + 4000)).toEqual({ white: 4000, black: 5000 });
  });
});

describe('GameClock state', () => {
  it('is saved and restored without losing time', () => {
    const start = 1_000_000;
    const clock = new GameClock({ initialSeconds: 10, incrementSeconds: 1 }, 'white', start);
    clock.press(start + 2500);
    const restored = GameClock.restore(JSON.parse(JSON.stringify(clock.state())));
    expect(restored.read(start + 4000)).toEqual(clock.read(start + 4000));
    expect(restored.flagAt()).toBe(start + 2500 + 10_000);
    restored.stop(start + 3000);
    expect(restored.flagAt()).toBeNull();
    expect(clock.flagAt()).toBe(start + 12_500);
  });
});
