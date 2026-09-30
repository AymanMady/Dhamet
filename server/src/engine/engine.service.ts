import { Injectable } from '@nestjs/common';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { Color, EngineSnapshot, GameJson, LegalMove, MoveJson, PlayOutcome } from './engine.types';

/** The object exported by the bundle built from `engine_bridge/`. */
interface EngineBridge {
  create(id: string): string;
  load(id: string, gameJson: string): string;
  play(id: string, moveJson: string, timestamp: string): string;
  resign(id: string, color: string): string;
  loseOnTime(id: string, color: string): string;
  snapshot(id: string): string;
  legalMoves(id: string): string;
  close(id: string): void;
  size(): number;
}

type BridgeResponse<T> =
  ({ ok: true } & T) | { ok: false; error: { code: string; message: string } };

interface Snapshotted {
  snapshot: EngineSnapshot;
}

const BUNDLE_PATH = join(__dirname, 'generated', 'dhamet_engine.js');

function loadBridge(): EngineBridge {
  if (!existsSync(BUNDLE_PATH)) {
    throw new Error(`Engine bundle missing at ${BUNDLE_PATH}: run "npm run build:engine"`);
  }
  // eslint-disable-next-line @typescript-eslint/no-require-imports -- generated CommonJS bundle
  return require(BUNDLE_PATH) as EngineBridge;
}

/** Raised when the engine refuses a call that the server should never make. */
export class EngineError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(`${code}: ${message}`);
  }
}

/**
 * The Dhamet rules engine (Dart, compiled to JavaScript).
 *
 * Games stay open in the engine, keyed by game id, from [create] or [load]
 * to [close]: a move costs one engine call instead of replaying the whole
 * history.
 */
@Injectable()
export class EngineService {
  private readonly bridge = loadBridge();

  /** Opens a new game under [id] with the standard rules (online games never use others). */
  create(id: string): EngineSnapshot {
    return this.snapshotOf(this.bridge.create(id));
  }

  /** Opens a saved `Game` JSON under [id], replaying and checking every move. */
  load(id: string, game: GameJson): EngineSnapshot {
    return this.snapshotOf(this.bridge.load(id, JSON.stringify(game)));
  }

  /** Plays [move] (untrusted `Move` JSON) at [playedAt]. */
  play(id: string, move: unknown, playedAt: Date): PlayOutcome {
    const response = JSON.parse(
      this.bridge.play(id, JSON.stringify(move), playedAt.toISOString()),
    ) as BridgeResponse<Snapshotted & { move: MoveJson }>;
    if (response.ok) {
      return { ok: true, move: response.move, snapshot: response.snapshot };
    }
    const { code, message } = response.error;
    if (code === 'ILLEGAL_MOVE' || code === 'GAME_OVER') return { ok: false, code, message };
    throw new EngineError(code, message);
  }

  resign(id: string, color: Color): EngineSnapshot {
    return this.snapshotOf(this.bridge.resign(id, color));
  }

  loseOnTime(id: string, color: Color): EngineSnapshot {
    return this.snapshotOf(this.bridge.loseOnTime(id, color));
  }

  snapshot(id: string): EngineSnapshot {
    return this.snapshotOf(this.bridge.snapshot(id));
  }

  legalMoves(id: string): LegalMove[] {
    const response = JSON.parse(this.bridge.legalMoves(id)) as BridgeResponse<{
      moves: LegalMove[];
    }>;
    return this.unwrap(response).moves;
  }

  close(id: string): void {
    this.bridge.close(id);
  }

  /** Number of games open in the engine. */
  get openGames(): number {
    return this.bridge.size();
  }

  private snapshotOf(json: string): EngineSnapshot {
    return this.unwrap(JSON.parse(json) as BridgeResponse<Snapshotted>).snapshot;
  }

  private unwrap<T>(response: BridgeResponse<T>): T {
    if (!response.ok) throw new EngineError(response.error.code, response.error.message);
    return response;
  }
}
