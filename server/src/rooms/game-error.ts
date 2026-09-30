/** `error.data.code` values (docs/multiplayer.md), plus INTERNAL_ERROR for server faults. */
export type GameErrorCode =
  | 'UNAUTHENTICATED'
  | 'ROOM_NOT_FOUND'
  | 'ROOM_FULL'
  | 'NOT_IN_ROOM'
  | 'GAME_NOT_STARTED'
  | 'GAME_OVER'
  | 'NOT_YOUR_TURN'
  | 'STALE_PLY'
  | 'ILLEGAL_MOVE'
  | 'INVALID_MESSAGE'
  | 'INTERNAL_ERROR';

/** A refused WebSocket request, sent back to the client as an `error` event. */
export class GameError extends Error {
  constructor(
    readonly code: GameErrorCode,
    message: string,
  ) {
    super(message);
  }
}
