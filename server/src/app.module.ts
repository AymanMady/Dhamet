import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { AppConfig, appConfig } from './config/app.config';
import { typeOrmOptions } from './database/typeorm-options';
import { EngineModule } from './engine/engine.module';
import { GamesModule } from './games/games.module';
import { HealthController } from './health/health.controller';
import { RankingModule } from './ranking/ranking.module';
import { RoomsModule } from './rooms/rooms.module';
import { TournamentsModule } from './tournaments/tournaments.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true, load: [appConfig] }),
    TypeOrmModule.forRootAsync({
      inject: [appConfig.KEY],
      useFactory: (settings: AppConfig) => typeOrmOptions(settings.database),
    }),
    EngineModule,
    AuthModule,
    UsersModule,
    RankingModule,
    GamesModule,
    RoomsModule,
    TournamentsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
