import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { LeaderboardController } from './leaderboard.controller';
import { Ranking } from './ranking.entity';
import { RankingService } from './ranking.service';

@Module({
  imports: [TypeOrmModule.forFeature([Ranking]), UsersModule],
  controllers: [LeaderboardController],
  providers: [RankingService],
  exports: [RankingService],
})
export class RankingModule {}
