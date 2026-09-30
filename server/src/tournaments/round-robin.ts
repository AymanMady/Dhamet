export interface Pairing<T> {
  white: T;
  black: T;
}

/**
 * Round-robin schedule by the circle method: every player meets every other
 * exactly once. With an odd number of players, one player rests each round.
 *
 * Colours: a player's games against the rotating players give exactly as
 * many Whites as Blacks, and the games of the fixed player alternate, so
 * every player's White and Black counts differ by at most one.
 */
export function roundRobin<T>(players: readonly T[]): Pairing<T>[][] {
  if (players.length < 2) return [];
  const even = players.length % 2 === 0;
  // With an odd count, the fixed seat is the rest: its "games" are skipped.
  const rotating = even ? players.slice(0, -1) : [...players];
  const fixed = even ? players.at(-1) : undefined;
  const size = rotating.length; // always odd
  const rounds: Pairing<T>[][] = [];
  for (let round = 0; round < size; round++) {
    const pairings: Pairing<T>[] = [];
    const seated = rotating[round] as T;
    if (fixed !== undefined) {
      pairings.push(
        round % 2 === 0 ? { white: seated, black: fixed } : { white: fixed, black: seated },
      );
    }
    for (let offset = 1; offset <= (size - 1) / 2; offset++) {
      pairings.push({
        white: rotating[(round + offset) % size] as T,
        black: rotating[(round - offset + size) % size] as T,
      });
    }
    rounds.push(pairings);
  }
  return rounds;
}
