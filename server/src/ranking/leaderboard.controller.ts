import { Controller, Get, Query } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { LeaderboardEntry, RankingService } from './ranking.service';

class LeaderboardQuery {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(200)
  limit = 50;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset = 0;
}

@Controller('leaderboard')
export class LeaderboardController {
  constructor(private readonly ranking: RankingService) {}

  /** Registered accounts by rating; guests never play rated games and are left out. */
  @Get()
  leaderboard(@Query() query: LeaderboardQuery): Promise<LeaderboardEntry[]> {
    return this.ranking.leaderboard(query.limit, query.offset);
  }
}
