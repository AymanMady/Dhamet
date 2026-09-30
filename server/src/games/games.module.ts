import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RankingModule } from '../ranking/ranking.module';
import { UsersModule } from '../users/users.module';
import { GamePlayer } from './game-player.entity';
import { Game } from './game.entity';
import { GamesController } from './games.controller';
import { GamesService } from './games.service';
import { Move } from './move.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Game, GamePlayer, Move]), RankingModule, UsersModule],
  controllers: [GamesController],
  providers: [GamesService],
  exports: [GamesService],
})
export class GamesModule {}
