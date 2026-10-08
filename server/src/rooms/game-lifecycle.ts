import { Color, GameResultJson } from '../engine/engine.types';
import { Tx } from '../realtime/transactions';

export interface StartedGame {
  gameId: string;
  tournamentMatchId: string | null;
}

export interface FinishedGame extends StartedGame {
  result: GameResultJson;
  /** User id of each player. */
  players: Record<Color, string>;
}

/**
 * Notified of the start and end of every online game (e.g. by tournaments),
 * inside the transaction of its room.
 */
export interface GameLifecycleListener {
  gameStarted(tx: Tx, game: StartedGame): Promise<void>;
  gameFinished(tx: Tx, game: FinishedGame): Promise<void>;
}
