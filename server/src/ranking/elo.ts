/** Elo rating (docs/multiplayer.md, "Classement Elo"). */

export const ELO_K = 32;

/** Expected score of a player rated [rating] against [opponentRating]. */
export function expectedScore(rating: number, opponentRating: number): number {
  return 1 / (1 + 10 ** ((opponentRating - rating) / 400));
}

/**
 * Rating changes after a game where White scored [whiteScore] (1 win, 0.5
 * draw, 0 loss). Rounded to integers; Black's change is the opposite of
 * White's, so no rating point is created or lost.
 */
export function eloChanges(
  whiteRating: number,
  blackRating: number,
  whiteScore: number,
): { white: number; black: number } {
  const white = Math.round(ELO_K * (whiteScore - expectedScore(whiteRating, blackRating)));
  return { white, black: 0 - white };
}
