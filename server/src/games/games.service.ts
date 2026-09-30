import { Injectable, NotFoundException, OnApplicationBootstrap } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';
import { Color, COLORS, GameJson, GameResultJson, MoveJson } from '../engine/engine.types';
import { RankingService, RatingChanges } from '../ranking/ranking.service';
import { TimeControl } from '../rooms/time-control';
import { User } from '../users/user.entity';
import { toUserView, UserView } from '../users/user.view';
import { GamePlayer } from './game-player.entity';
import { Game, GameStatus } from './game.entity';
import { Move } from './move.entity';

/** `gameSummary` in docs/multiplayer.md. */
export interface GameSummary {
  id: string;
  roomCode: string;
  white: UserView;
  black: UserView;
  status: GameStatus;
  result: GameResultJson | null;
  rated: boolean;
  startedAt: string;
  finishedAt: string | null;
  plyCount: number;
}

export interface NewGame {
  id: string;
  roomCode: string;
  rated: boolean;
  timeControl: TimeControl | null;
  tournamentMatchId: string | null;
  game: GameJson;
  players: Record<Color, { id: string; rating: number }>;
  startedAt: Date;
}

export interface PlayedMove {
  gameId: string;
  ply: number;
  userId: string;
  move: MoveJson;
  playedAt: Date;
  game: GameJson;
}

/** Persistence of online games. The games themselves are run by `GameplayService`. */
@Injectable()
export class GamesService implements OnApplicationBootstrap {
  /** Game ends are applied one at a time: they update the players' ratings. */
  private finishing: Promise<unknown> = Promise.resolve();

  constructor(
    @InjectRepository(Game) private readonly games: Repository<Game>,
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly ranking: RankingService,
  ) {}

  /** Games still "playing" were cut by a restart: active games only live in memory. */
  async onApplicationBootstrap(): Promise<void> {
    await this.games.update({ status: 'playing' }, { status: 'aborted', finishedAt: new Date() });
  }

  async start(game: NewGame): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      await manager.insert(Game, {
        id: game.id,
        roomCode: game.roomCode,
        rated: game.rated,
        status: 'playing',
        gameJson: game.game,
        resultJson: null,
        timeControl: game.timeControl,
        tournamentMatchId: game.tournamentMatchId,
        plyCount: 0,
        startedAt: game.startedAt,
        finishedAt: null,
      });
      for (const color of COLORS) {
        const player = game.players[color];
        await manager.insert(GamePlayer, {
          gameId: game.id,
          userId: player.id,
          color,
          ratingBefore: player.rating,
          ratingAfter: null,
        });
      }
    });
  }

  async recordMove(move: PlayedMove): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      await manager.insert(Move, {
        gameId: move.gameId,
        ply: move.ply,
        userId: move.userId,
        moveJson: move.move,
        playedAt: move.playedAt,
      });
      await manager.update(Game, move.gameId, { gameJson: move.game, plyCount: move.ply });
    });
  }

  /**
   * Saves the end of a game and updates its players (statistics, and
   * ratings for a rated game). Returns the rating changes of a rated game.
   */
  finish(
    gameId: string,
    end: { game: GameJson; result: GameResultJson; plyCount: number; finishedAt: Date },
  ): Promise<RatingChanges | null> {
    const task = this.finishing.then(() =>
      this.dataSource.transaction(async (manager) => {
        const game = await manager.findOneOrFail(Game, {
          where: { id: gameId },
          relations: { players: true },
        });
        const users = await manager.findBy(User, { id: In(game.players.map((p) => p.userId)) });
        const byColor = (color: Color): User => {
          const player = game.players.find((p) => p.color === color);
          const user = users.find((u) => u.id === player?.userId);
          if (!user) throw new Error(`Game ${gameId} has no ${color} player`);
          return user;
        };
        const players = { white: byColor('white'), black: byColor('black') };
        const changes = await this.ranking.recordResult(manager, game, players, end.result);
        if (changes) {
          for (const player of game.players) {
            await manager.update(GamePlayer, player.id, {
              ratingAfter: players[player.color].rating,
            });
          }
        }
        await manager.update(Game, gameId, {
          status: 'finished',
          gameJson: end.game,
          resultJson: end.result,
          plyCount: end.plyCount,
          finishedAt: end.finishedAt,
        });
        return changes;
      }),
    );
    this.finishing = task.catch(() => undefined);
    return task;
  }

  /** The summary and the engine `Game` JSON of game [id]. */
  async detail(id: string): Promise<{ summary: GameSummary; game: GameJson }> {
    const game = await this.games.findOne({
      where: { id },
      relations: { players: { user: true } },
    });
    if (!game) throw new NotFoundException('Game not found');
    return { summary: toSummary(game), game: game.gameJson };
  }

  /** The games of [userId], most recent first. */
  async forUser(userId: string, limit: number): Promise<GameSummary[]> {
    const games = await this.games
      .createQueryBuilder('game')
      .innerJoin('game.players', 'self', 'self.userId = :userId', { userId })
      .leftJoinAndSelect('game.players', 'player')
      .leftJoinAndSelect('player.user', 'user')
      .orderBy('game.startedAt', 'DESC')
      .take(limit)
      .getMany();
    return games.map(toSummary);
  }
}

function toSummary(game: Game): GameSummary {
  const player = (color: Color): UserView => {
    const found = game.players.find((p) => p.color === color);
    if (!found) throw new Error(`Game ${game.id} has no ${color} player`);
    return toUserView(found.user);
  };
  return {
    id: game.id,
    roomCode: game.roomCode,
    white: player('white'),
    black: player('black'),
    status: game.status,
    result: game.resultJson,
    rated: game.rated,
    startedAt: game.startedAt.toISOString(),
    finishedAt: game.finishedAt?.toISOString() ?? null,
    plyCount: game.plyCount,
  };
}
