import { roundRobin } from './round-robin';

function players(count: number): string[] {
  return Array.from({ length: count }, (_, i) => `p${i + 1}`);
}

describe('roundRobin (circle method)', () => {
  it('has no round for fewer than two players', () => {
    expect(roundRobin([])).toEqual([]);
    expect(roundRobin(['alone'])).toEqual([]);
  });

  it('pairs two players once', () => {
    expect(roundRobin(['a', 'b'])).toEqual([[{ white: 'a', black: 'b' }]]);
  });

  it.each([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16])('schedules %i players', (count) => {
    const rounds = roundRobin(players(count));
    // n - 1 rounds for an even count, n rounds (one rest each) for an odd count.
    expect(rounds).toHaveLength(count % 2 === 0 ? count - 1 : count);

    const meetings = new Map<string, number>();
    const whites = new Map<string, number>();
    const blacks = new Map<string, number>();
    for (const round of rounds) {
      expect(round).toHaveLength(Math.floor(count / 2));
      const busy = round.flatMap(({ white, black }) => [white, black]);
      expect(new Set(busy).size).toBe(busy.length); // nobody plays twice in a round
      for (const { white, black } of round) {
        expect(white).not.toBe(black);
        const key = [white, black].sort().join('-');
        meetings.set(key, (meetings.get(key) ?? 0) + 1);
        whites.set(white, (whites.get(white) ?? 0) + 1);
        blacks.set(black, (blacks.get(black) ?? 0) + 1);
      }
    }

    // Every pair meets exactly once.
    expect(meetings.size).toBe((count * (count - 1)) / 2);
    expect([...meetings.values()].every((times) => times === 1)).toBe(true);

    // Every player plays everyone, with balanced colours.
    for (const player of players(count)) {
      const white = whites.get(player) ?? 0;
      const black = blacks.get(player) ?? 0;
      expect(white + black).toBe(count - 1);
      expect(Math.abs(white - black)).toBeLessThanOrEqual(1);
    }
  });
});
