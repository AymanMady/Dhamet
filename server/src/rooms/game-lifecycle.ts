import { Color, GameResultJson } from '../engine/engine.types';

export interface StartedGame {
  gameId: string;
  tournamentMatchId: string | null;
}

export interface FinishedGame extends StartedGame {
  result: GameResultJson;
  /** User id of each player. */
  players: Record<Color, string>;
}

/** Notified of the start and end of every online game (e.g. by tournaments). */
export interface GameLifecycleListener {
  gameStarted(game: StartedGame): Promise<void>;
  gameFinished(game: FinishedGame): Promise<void>;
}
