import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AppConfig, appConfig } from '../config/app.config';
import { EngineService } from '../engine/engine.service';
import { Color, EngineSnapshot, GameJson } from '../engine/engine.types';
import { Game } from '../games/game.entity';
import { GamesService } from '../games/games.service';
import { Tx } from '../realtime/transactions';
import { ActiveRoom, RoomView } from './active-room';
import { Clocks, GameClock } from './game-clock';
import { GameError } from './game-error';
import { GameLifecycleListener } from './game-lifecycle';
import { RoomStore } from './room-store';

export interface GameSyncData {
  room: RoomView;
  gameId: string;
  game: GameJson;
  clocks?: Clocks;
}

/**
 * Runs the online games: the server is the authority. Every move is checked
 * (membership, game state, turn, ply, then legality by the engine), played
 * by the engine, timestamped, saved and broadcast.
 *
 * Every method runs inside the transaction holding the lock of the room
 * (`RoomsService`), with the time [now] of the request.
 */
@Injectable()
export class GameplayService {
  private readonly listeners: GameLifecycleListener[] = [];

  constructor(
    private readonly engine: EngineService,
    private readonly games: GamesService,
    private readonly store: RoomStore,
    @Inject(appConfig.KEY) private readonly settings: AppConfig,
  ) {}

  subscribe(listener: GameLifecycleListener): void {
    this.listeners.push(listener);
  }

  /** Starts the game of [room], whose two players are ready. */
  async startInRoom(tx: Tx, room: ActiveRoom, now: number): Promise<void> {
    const white = room.user(room.playerWithColor('white').userId);
    const black = room.user(room.playerWithColor('black').userId);
    const id = randomUUID();
    const snapshot = this.engine.create(id);
    const rated = room.rated && !white.isGuest && !black.isGuest;
    try {
      await this.games.start(tx, {
        id,
        roomCode: room.code,
        rated,
        timeControl: room.timeControl,
        tournamentMatchId: room.tournamentMatchId,
        game: snapshot.game,
        players: { white, black },
        startedAt: new Date(now),
      });
    } catch (error) {
      this.engine.close(id);
      throw error;
    }
    room.entity.gameId = id;
    room.setClock(
      room.timeControl ? new GameClock(room.timeControl, snapshot.currentPlayer, now) : null,
    );
    room.status = 'playing';
    for (const listener of this.listeners) {
      await listener.gameStarted(tx, { gameId: id, tournamentMatchId: room.tournamentMatchId });
    }
    this.send(tx, room.memberIds(), 'game:started', {
      room: room.view(),
      gameId: id,
      game: snapshot.game,
    });
  }

  /** `game:move`, validated in the order of docs/multiplayer.md. */
  async moveInRoom(
    tx: Tx,
    room: ActiveRoom,
    userId: string,
    ply: number,
    move: unknown,
    now: number,
  ): Promise<void> {
    const game = await this.gameInProgress(tx, room);
    const color = this.colorOf(room, userId);
    const snapshot = this.engine.ensure(game.id, game.gameJson);
    if (color !== snapshot.currentPlayer) {
      throw new GameError('NOT_YOUR_TURN', `It is ${snapshot.currentPlayer}'s turn`);
    }
    if (ply !== snapshot.plyCount) {
      throw new GameError('STALE_PLY', `Expected ply ${snapshot.plyCount}, got ${ply}`);
    }
    // A clock that ran out has already ended the game (`settleInRoom`).
    const outcome = this.engine.play(game.id, move, new Date(now));
    if (!outcome.ok) throw new GameError(outcome.code, outcome.message);
    const clock = room.clock();
    clock?.press(now);
    room.setClock(clock);
    await this.games.recordMove(tx, {
      gameId: game.id,
      ply: outcome.snapshot.plyCount,
      userId,
      move: outcome.move,
      playedAt: new Date(now),
      game: outcome.snapshot.game,
    });
    this.send(tx, room.memberIds(), 'game:moved', {
      code: room.code,
      gameId: game.id,
      ply: outcome.snapshot.plyCount,
      move: outcome.move,
      ...room.clocksAt(now),
    });
    if (outcome.snapshot.result) await this.endInRoom(tx, room, outcome.snapshot, now, now);
  }

  /** [userId] resigns at [at]; the request came at [now]. */
  async resignInRoom(
    tx: Tx,
    room: ActiveRoom,
    userId: string,
    at: number,
    now: number,
  ): Promise<void> {
    const game = await this.gameInProgress(tx, room);
    this.engine.ensure(game.id, game.gameJson);
    const snapshot = this.engine.resign(game.id, this.colorOf(room, userId));
    await this.endInRoom(tx, room, snapshot, at, now);
  }

  /** The full state of the game of [room] (in progress or over). */
  async syncInRoom(tx: Tx, room: ActiveRoom, now: number): Promise<GameSyncData> {
    if (!room.gameId) throw new GameError('GAME_NOT_STARTED', 'The game has not started');
    const game = await this.games.get(tx, room.gameId);
    return { room: room.view(), gameId: game.id, game: game.gameJson, ...room.clocksAt(now) };
  }

  /**
   * Ends the game of [room] if, at [now], a clock has run out or a
   * disconnected player has not come back in time: whichever came first,
   * at the time it happened.
   */
  async settleInRoom(tx: Tx, room: ActiveRoom, now: number): Promise<void> {
    if (room.status !== 'playing') return;
    const flagAt = room.clock()?.flagAt() ?? null;
    let forfeit: { userId: string; at: number } | null = null;
    for (const seat of room.players) {
      if (seat.connected || seat.forfeitAt === null) continue;
      if (!forfeit || seat.forfeitAt < forfeit.at) {
        forfeit = { userId: seat.userId, at: seat.forfeitAt };
      }
    }
    if (flagAt !== null && flagAt <= now && (!forfeit || flagAt <= forfeit.at)) {
      const game = await this.gameInProgress(tx, room);
      const snapshot = this.engine.ensure(game.id, game.gameJson);
      const lost = this.engine.loseOnTime(game.id, snapshot.currentPlayer);
      await this.endInRoom(tx, room, lost, flagAt, now);
    } else if (forfeit && forfeit.at <= now) {
      await this.resignInRoom(tx, room, forfeit.userId, forfeit.at, now);
    }
  }

  private async gameInProgress(tx: Tx, room: ActiveRoom): Promise<Game> {
    if (room.status === 'waiting' || !room.gameId) {
      throw new GameError('GAME_NOT_STARTED', 'The game has not started');
    }
    if (room.status === 'finished') throw new GameError('GAME_OVER', 'The game is over');
    return this.games.get(tx, room.gameId);
  }

  private colorOf(room: ActiveRoom, userId: string): Color {
    const player = room.player(userId);
    if (!player) throw new GameError('NOT_IN_ROOM', `You are not in room ${room.code}`);
    return player.color;
  }

  /**
   * Finishes the game of [room] with [snapshot] (which has a result), as of
   * [at]: saves it, updates ratings and listeners, then broadcasts
   * `game:over`. The room stays open for the grace period from [now], for
   * the players to see the result.
   */
  private async endInRoom(
    tx: Tx,
    room: ActiveRoom,
    snapshot: EngineSnapshot,
    at: number,
    now: number,
  ): Promise<void> {
    const gameId = room.gameId;
    const result = snapshot.result;
    if (!gameId || !result) throw new Error(`Room ${room.code} has no finished game`);
    const clock = room.clock();
    clock?.stop(at);
    room.setClock(clock);
    room.status = 'finished';
    for (const seat of room.players) seat.forfeitAt = null;
    room.entity.expiresAt = new Date(
      Math.max(at, now) + this.settings.reconnectGraceSeconds * 1000,
    );
    this.engine.close(gameId);
    const ratingChanges = await this.games.finish(tx, gameId, {
      game: snapshot.game,
      result,
      plyCount: snapshot.plyCount,
      finishedAt: new Date(at),
    });
    await this.store.refreshUsers(tx, room);
    const players = {
      white: room.playerWithColor('white').userId,
      black: room.playerWithColor('black').userId,
    };
    for (const listener of this.listeners) {
      await listener.gameFinished(tx, {
        gameId,
        tournamentMatchId: room.tournamentMatchId,
        result,
        players,
      });
    }
    this.send(tx, room.memberIds(), 'game:over', {
      code: room.code,
      gameId,
      result,
      ...(ratingChanges ? { ratingChanges } : {}),
    });
  }

  private send(tx: Tx, to: string[], event: string, data: unknown): void {
    tx.publish({ deliveries: [{ to, event, data }] });
  }
}
