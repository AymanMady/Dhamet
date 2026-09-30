import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { Color, GameResultJson } from '../engine/engine.types';
import { User } from '../users/user.entity';
import { toUserView, UserView } from '../users/user.view';
import { UsersService } from '../users/users.service';
import { eloChanges } from './elo';
import { Ranking } from './ranking.entity';

/** Rating change of each player of a rated game, keyed by user id. */
export type RatingChanges = Record<string, number>;

export interface LeaderboardEntry {
  rank: number;
  user: UserView;
}

@Injectable()
export class RankingService {
  constructor(private readonly users: UsersService) {}

  async leaderboard(limit: number, offset: number): Promise<LeaderboardEntry[]> {
    const users = await this.users.leaderboard(limit, offset);
    return users.map((user, index) => ({ rank: offset + index + 1, user: toUserView(user) }));
  }

  /**
   * Records [result] for both players inside [manager]'s transaction: wins,
   * losses and draws for every game, and the Elo update with its history
   * when the game is [rated]. Returns the rating changes of a rated game.
   */
  async recordResult(
    manager: EntityManager,
    game: { id: string; rated: boolean },
    players: Record<Color, User>,
    result: GameResultJson,
  ): Promise<RatingChanges | null> {
    const whiteScore = result.winner === null ? 0.5 : result.winner === 'white' ? 1 : 0;
    const changes = game.rated
      ? eloChanges(players.white.rating, players.black.rating, whiteScore)
      : { white: 0, black: 0 };
    for (const color of ['white', 'black'] as const) {
      const user = players[color];
      const score = color === 'white' ? whiteScore : 1 - whiteScore;
      const ratingBefore = user.rating;
      user.rating += changes[color];
      if (score === 1) user.wins++;
      else if (score === 0) user.losses++;
      else user.draws++;
      await manager.update(User, user.id, {
        rating: user.rating,
        wins: user.wins,
        losses: user.losses,
        draws: user.draws,
      });
      if (game.rated) {
        await manager.insert(Ranking, {
          userId: user.id,
          gameId: game.id,
          ratingBefore,
          ratingAfter: user.rating,
        });
      }
    }
    if (!game.rated) return null;
    return { [players.white.id]: changes.white, [players.black.id]: changes.black };
  }
}
