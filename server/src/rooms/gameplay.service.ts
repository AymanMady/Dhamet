import { Inject, Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AppConfig, appConfig } from '../config/app.config';
import { EngineService } from '../engine/engine.service';
import { Color, EngineSnapshot, GameJson } from '../engine/engine.types';
import { GamesService } from '../games/games.service';
import { RatingChanges } from '../ranking/ranking.service';
import { toUserView } from '../users/user.view';
import { UsersService } from '../users/users.service';
import { ActiveGame, ActiveRoom, RoomView } from './active-room';
import { ConnectionRegistry } from './connection-registry';
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
 * Methods whose name ends in `InRoom` must be called from inside
 * `room.run`; the others queue themselves.
 */
@Injectable()
export class GameplayService {
  private readonly logger = new Logger(GameplayService.name);
  private readonly listeners: GameLifecycleListener[] = [];

  constructor(
    private readonly engine: EngineService,
    private readonly games: GamesService,
    private readonly users: UsersService,
    private readonly store: RoomStore,
    private readonly connections: ConnectionRegistry,
    @Inject(appConfig.KEY) private readonly settings: AppConfig,
  ) {}

  subscribe(listener: GameLifecycleListener): void {
    this.listeners.push(listener);
  }

  /** Starts the game of [room], whose two players are ready. */
  async startInRoom(room: ActiveRoom): Promise<void> {
    const white = room.playerWithColor('white').user;
    const black = room.playerWithColor('black').user;
    const id = randomUUID();
    const startedAt = new Date();
    const snapshot = this.engine.create(id);
    const rated = room.rated && !white.isGuest && !black.isGuest;
    try {
      await this.games.start({
        id,
        roomCode: room.code,
        rated,
        timeControl: room.timeControl,
        tournamentMatchId: room.tournamentMatchId,
        game: snapshot.game,
        players: { white, black },
        startedAt,
      });
    } catch (error) {
      this.engine.close(id);
      throw error;
    }
    const clock = room.timeControl
      ? new GameClock(room.timeControl, snapshot.currentPlayer, startedAt.getTime())
      : null;
    room.game = { id, rated, snapshot, clock };
    room.status = 'playing';
    await this.store.saveStatus(room);
    await this.notify((listener) =>
      listener.gameStarted({ gameId: id, tournamentMatchId: room.tournamentMatchId }),
    );
    this.armFlagTimer(room);
    this.connections.broadcast(room.memberIds(), 'game:started', {
      room: room.view(),
      gameId: id,
      game: snapshot.game,
    });
  }

  /** `game:move`, validated in the order of docs/multiplayer.md. */
  async move(userId: string, code: string, ply: number, move: unknown): Promise<void> {
    const room = this.store.getAsMember(code, userId);
    await room.run(async () => {
      const game = this.gameInProgress(room);
      const color = this.colorOf(room, userId);
      if (color !== game.snapshot.currentPlayer) {
        throw new GameError('NOT_YOUR_TURN', `It is ${game.snapshot.currentPlayer}'s turn`);
      }
      if (ply !== game.snapshot.plyCount) {
        throw new GameError('STALE_PLY', `Expected ply ${game.snapshot.plyCount}, got ${ply}`);
      }
      const now = new Date();
      if (game.clock?.hasFlagged(now.getTime())) {
        await this.endInRoom(room, this.engine.loseOnTime(game.id, color), now);
        throw new GameError('GAME_OVER', 'Your time is up');
      }
      const outcome = this.engine.play(game.id, move, now);
      if (!outcome.ok) throw new GameError(outcome.code, outcome.message);
      game.snapshot = outcome.snapshot;
      game.clock?.press(now.getTime());
      await this.games.recordMove({
        gameId: game.id,
        ply: outcome.snapshot.plyCount,
        userId,
        move: outcome.move,
        playedAt: now,
        game: outcome.snapshot.game,
      });
      this.connections.broadcast(room.memberIds(), 'game:moved', {
        code: room.code,
        gameId: game.id,
        ply: outcome.snapshot.plyCount,
        move: outcome.move,
        ...this.clocksOf(game, now),
      });
      if (outcome.snapshot.result) await this.endInRoom(room, outcome.snapshot, now);
      else this.armFlagTimer(room);
    });
  }

  async resign(userId: string, code: string): Promise<void> {
    const room = this.store.getAsMember(code, userId);
    await room.run(() => this.resignInRoom(room, userId));
  }

  async resignInRoom(room: ActiveRoom, userId: string): Promise<void> {
    const game = this.gameInProgress(room);
    await this.endInRoom(room, this.engine.resign(game.id, this.colorOf(room, userId)), new Date());
  }

  async sync(userId: string, code: string): Promise<GameSyncData> {
    const room = this.store.getAsMember(code, userId);
    return await room.run(() => this.syncInRoom(room));
  }

  /** The full state of the game of [room] (in progress or over). */
  syncInRoom(room: ActiveRoom): GameSyncData {
    const game = room.game;
    if (!game) throw new GameError('GAME_NOT_STARTED', 'The game has not started');
    return {
      room: room.view(),
      gameId: game.id,
      game: game.snapshot.game,
      ...this.clocksOf(game, new Date()),
    };
  }

  /** [userId] left a game in progress: they forfeit unless they come back in time. */
  startForfeitTimerInRoom(room: ActiveRoom, userId: string): void {
    this.cancelForfeitTimerInRoom(room, userId);
    const timer = setTimeout(() => {
      room
        .run(async () => {
          room.forfeitTimers.delete(userId);
          if (room.status === 'playing' && room.player(userId)?.connected === false) {
            await this.resignInRoom(room, userId);
          }
        })
        .catch((error: unknown) => {
          this.logger.error(error);
        });
    }, this.settings.reconnectGraceSeconds * 1000);
    room.forfeitTimers.set(userId, timer);
  }

  cancelForfeitTimerInRoom(room: ActiveRoom, userId: string): void {
    clearTimeout(room.forfeitTimers.get(userId));
    room.forfeitTimers.delete(userId);
  }

  private gameInProgress(room: ActiveRoom): ActiveGame {
    if (room.status === 'waiting' || !room.game) {
      throw new GameError('GAME_NOT_STARTED', 'The game has not started');
    }
    if (room.status === 'finished') throw new GameError('GAME_OVER', 'The game is over');
    return room.game;
  }

  private colorOf(room: ActiveRoom, userId: string): Color {
    const player = room.player(userId);
    if (!player) throw new GameError('NOT_IN_ROOM', `You are not in room ${room.code}`);
    return player.color;
  }

  private clocksOf(game: ActiveGame, now: Date): { clocks?: Clocks } {
    return game.clock ? { clocks: game.clock.read(now.getTime()) } : {};
  }

  /** Ends the game on time when the side to move runs out of it. */
  private armFlagTimer(room: ActiveRoom): void {
    if (room.flagTimer) clearTimeout(room.flagTimer);
    room.flagTimer = null;
    const clock = room.game?.clock;
    if (!clock) return;
    room.flagTimer = setTimeout(
      () => {
        room
          .run(async () => {
            const game = room.game;
            if (room.status !== 'playing' || !game) return;
            const now = new Date();
            if (!clock.hasFlagged(now.getTime())) {
              this.armFlagTimer(room);
              return;
            }
            await this.endInRoom(
              room,
              this.engine.loseOnTime(game.id, game.snapshot.currentPlayer),
              now,
            );
          })
          .catch((error: unknown) => {
            this.logger.error(error);
          });
      },
      Math.max(0, clock.msUntilFlag(Date.now())),
    );
  }

  /**
   * Finishes the game of [room] with [snapshot] (which has a result): saves
   * it, updates ratings and listeners, then broadcasts `game:over`.
   */
  private async endInRoom(room: ActiveRoom, snapshot: EngineSnapshot, at: Date): Promise<void> {
    const game = room.game;
    const result = snapshot.result;
    if (!game || !result) throw new Error(`Room ${room.code} has no finished game`);
    game.snapshot = snapshot;
    game.clock?.stop(at.getTime());
    room.status = 'finished';
    room.clearTimers();
    this.engine.close(game.id);
    const players = {
      white: room.playerWithColor('white').user.id,
      black: room.playerWithColor('black').user.id,
    };
    let ratingChanges: RatingChanges | null = null;
    try {
      ratingChanges = await this.games.finish(game.id, {
        game: snapshot.game,
        result,
        plyCount: snapshot.plyCount,
        finishedAt: at,
      });
      await this.store.saveStatus(room);
      for (const player of room.players) {
        const user = await this.users.findById(player.user.id);
        if (user) player.user = toUserView(user);
      }
    } catch (error) {
      this.logger.error(`Could not save the end of game ${game.id}`, error);
    }
    await this.notify((listener) =>
      listener.gameFinished({
        gameId: game.id,
        tournamentMatchId: room.tournamentMatchId,
        result,
        players,
      }),
    );
    this.connections.broadcast(room.memberIds(), 'game:over', {
      code: room.code,
      gameId: game.id,
      result,
      ...(ratingChanges ? { ratingChanges } : {}),
    });
    this.store.scheduleEviction(room, this.settings.reconnectGraceSeconds);
  }

  private async notify(call: (listener: GameLifecycleListener) => Promise<void>): Promise<void> {
    for (const listener of this.listeners) {
      try {
        await call(listener);
      } catch (error) {
        this.logger.error('Game lifecycle listener failed', error);
      }
    }
  }
}
