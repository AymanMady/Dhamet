import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
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

/** Games an instance keeps open in its engine, at most; the least recently used close first. */
const MAX_OPEN_GAMES = 200;

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
 * The database holds the games; the engine of an instance keeps the games
 * it played recently open, keyed by game id, so that a move usually costs
 * one engine call instead of replaying the whole history. [ensure] checks
 * that the open copy is still the saved game: another instance may have
 * played since.
 */
@Injectable()
export class EngineService {
  private readonly bridge = loadBridge();
  /** Instances of this service share the bundle (tests run several apps in one process). */
  private readonly prefix = `${randomUUID().slice(0, 8)}:`;
  /** The `Game` JSON of each game open in this engine, least recently used first. */
  private readonly opened = new Map<string, string>();

  /** Opens a new game under [id] with the standard rules (online games never use others). */
  create(id: string): EngineSnapshot {
    return this.remember(id, this.snapshotOf(this.bridge.create(this.key(id))));
  }

  /** Opens a saved `Game` JSON under [id], replaying and checking every move. */
  load(id: string, game: GameJson): EngineSnapshot {
    return this.remember(id, this.snapshotOf(this.bridge.load(this.key(id), JSON.stringify(game))));
  }

  /**
   * Game [id] as saved: [game]. Reuses the open copy if it is that very
   * game, otherwise loads it again.
   */
  ensure(id: string, game: GameJson): EngineSnapshot {
    const json = JSON.stringify(game);
    if (this.opened.get(id) === json) {
      this.opened.delete(id);
      this.opened.set(id, json);
      return this.snapshot(id);
    }
    if (this.opened.has(id)) this.close(id);
    return this.load(id, game);
  }

  /** Plays [move] (untrusted `Move` JSON) at [playedAt]. */
  play(id: string, move: unknown, playedAt: Date): PlayOutcome {
    const response = JSON.parse(
      this.bridge.play(this.key(id), JSON.stringify(move), playedAt.toISOString()),
    ) as BridgeResponse<Snapshotted & { move: MoveJson }>;
    if (response.ok) {
      this.remember(id, response.snapshot);
      return { ok: true, move: response.move, snapshot: response.snapshot };
    }
    const { code, message } = response.error;
    if (code === 'ILLEGAL_MOVE' || code === 'GAME_OVER') return { ok: false, code, message };
    throw new EngineError(code, message);
  }

  resign(id: string, color: Color): EngineSnapshot {
    return this.remember(id, this.snapshotOf(this.bridge.resign(this.key(id), color)));
  }

  loseOnTime(id: string, color: Color): EngineSnapshot {
    return this.remember(id, this.snapshotOf(this.bridge.loseOnTime(this.key(id), color)));
  }

  snapshot(id: string): EngineSnapshot {
    return this.snapshotOf(this.bridge.snapshot(this.key(id)));
  }

  legalMoves(id: string): LegalMove[] {
    const response = JSON.parse(this.bridge.legalMoves(this.key(id))) as BridgeResponse<{
      moves: LegalMove[];
    }>;
    return this.unwrap(response).moves;
  }

  close(id: string): void {
    this.opened.delete(id);
    this.bridge.close(this.key(id));
  }

  /** Number of games open in the engine. */
  get openGames(): number {
    return this.bridge.size();
  }

  private key(id: string): string {
    return this.prefix + id;
  }

  private remember(id: string, snapshot: EngineSnapshot): EngineSnapshot {
    this.opened.delete(id);
    this.opened.set(id, JSON.stringify(snapshot.game));
    for (const oldest of this.opened.keys()) {
      if (this.opened.size <= MAX_OPEN_GAMES) break;
      this.close(oldest);
    }
    return snapshot;
  }

  private snapshotOf(json: string): EngineSnapshot {
    return this.unwrap(JSON.parse(json) as BridgeResponse<Snapshotted>).snapshot;
  }

  private unwrap<T>(response: BridgeResponse<T>): T {
    if (!response.ok) throw new EngineError(response.error.code, response.error.message);
    return response;
  }
}
