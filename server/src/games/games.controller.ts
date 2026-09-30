import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { GameJson } from '../engine/engine.types';
import { UsersService } from '../users/users.service';
import { GameSummary, GamesService } from './games.service';

class UserGamesQuery {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit = 20;
}

@Controller()
export class GamesController {
  constructor(
    private readonly games: GamesService,
    private readonly users: UsersService,
  ) {}

  @Get('games/:id')
  game(@Param('id', ParseUUIDPipe) id: string): Promise<{ summary: GameSummary; game: GameJson }> {
    return this.games.detail(id);
  }

  @Get('users/:id/games')
  async userGames(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: UserGamesQuery,
  ): Promise<GameSummary[]> {
    await this.users.getById(id);
    return this.games.forUser(id, query.limit);
  }
}
