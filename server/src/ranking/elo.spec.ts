import { ELO_K, eloChanges, expectedScore } from './elo';

describe('Elo', () => {
  it('expects an even score between equal ratings', () => {
    expect(expectedScore(1200, 1200)).toBe(0.5);
  });

  it('follows 1 / (1 + 10^((Rb - Ra) / 400))', () => {
    expect(expectedScore(1600, 1200)).toBeCloseTo(1 / (1 + 10 ** -1), 10);
    expect(expectedScore(1200, 1600)).toBeCloseTo(1 / (1 + 10 ** 1), 10);
    expect(expectedScore(1400, 1250) + expectedScore(1250, 1400)).toBeCloseTo(1, 10);
  });

  it('uses K = 32', () => {
    expect(ELO_K).toBe(32);
    expect(eloChanges(1200, 1200, 1)).toEqual({ white: 16, black: -16 });
    expect(eloChanges(1200, 1200, 0)).toEqual({ white: -16, black: 16 });
  });

  it('gives nothing for a draw between equals', () => {
    expect(eloChanges(1200, 1200, 0.5)).toEqual({ white: 0, black: 0 });
  });

  it('rewards an upset more than an expected win', () => {
    // 32 * (1 - 1/(1 + 10^(400/400))) = 32 * 10/11 = 29.09
    expect(eloChanges(1200, 1600, 1)).toEqual({ white: 29, black: -29 });
    // 32 * (1 - 1/(1 + 10^(-400/400))) = 32 * 1/11 = 2.91
    expect(eloChanges(1600, 1200, 1)).toEqual({ white: 3, black: -3 });
  });

  it('rates a draw against a stronger player as a gain', () => {
    // 32 * (0.5 - 1/(1 + 10^(200/400))) = 32 * 0.2597 = 8.31
    expect(eloChanges(1300, 1500, 0.5)).toEqual({ white: 8, black: -8 });
  });

  it('never creates or destroys rating points', () => {
    for (const [white, black, score] of [
      [1200, 1213, 1],
      [987, 1500, 0.5],
      [2100, 1800, 0],
      [1500, 1500, 0.5],
    ] as const) {
      const changes = eloChanges(white, black, score);
      expect(changes.white + changes.black).toBe(0);
    }
  });
});
