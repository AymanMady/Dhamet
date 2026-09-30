/** JSON shapes of the Dart engine (see the README section "Sauvegarde (JSON)"). */

export const COLORS = ['white', 'black'] as const;

export type Color = (typeof COLORS)[number];

export type GameEndReason =
  'elimination' | 'blocked' | 'repetition' | 'agreement' | 'resignation' | 'timeout';

/** `GameResult` JSON: `winner` is null for a draw. */
export interface GameResultJson {
  winner: Color | null;
  reason: GameEndReason;
}

/** `Move` JSON. */
export interface MoveJson {
  piece: 'w' | 'W' | 'b' | 'B';
  from: string;
  path: string[];
  captured: string[];
  promotes: boolean;
}

/** `Game` JSON. The server stores and forwards it without looking inside. */
export interface GameJson {
  format: 'dhamet.game';
  version: number;
  undoPolicy: object;
  declaredResult: GameResultJson | null;
  history: object;
}

/** State of an open game after an engine call. */
export interface EngineSnapshot {
  currentPlayer: Color;
  plyCount: number;
  result: GameResultJson | null;
  pieceCounts: Record<Color, number>;
  game: GameJson;
}

export interface LegalMove {
  move: MoveJson;
  notation: string;
}

/** Outcome of `EngineService.play`: refusals are expected, not exceptional. */
export type PlayOutcome =
  | { ok: true; move: MoveJson; snapshot: EngineSnapshot }
  | { ok: false; code: 'ILLEGAL_MOVE' | 'GAME_OVER'; message: string };

export function opponentOf(color: Color): Color {
  return color === 'white' ? 'black' : 'white';
}
