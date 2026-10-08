import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { AccountsModule } from './accounts/accounts.module';
import { AuthModule } from './auth/auth.module';
import { AppConfig, appConfig, readDatabaseSettings } from './config/app.config';
import { runMigrationsLocked } from './database/migrations-lock';
import { typeOrmOptions } from './database/typeorm-options';
import { EngineModule } from './engine/engine.module';
import { GamesModule } from './games/games.module';
import { HealthController } from './health/health.controller';
import { PrivacyController } from './legal/privacy.controller';
import { RankingModule } from './ranking/ranking.module';
import { RealtimeModule } from './realtime/realtime.module';
import { RoomsModule } from './rooms/rooms.module';
import { TournamentsModule } from './tournaments/tournaments.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true, load: [appConfig] }),
    TypeOrmModule.forRootAsync({
      inject: [appConfig.KEY],
      useFactory: (settings: AppConfig) => typeOrmOptions(settings.database),
      // The schema is up to date before anything uses the database.
      dataSourceFactory: async (options) => {
        if (!options) throw new Error('Missing database options');
        const dataSource = await new DataSource(options).initialize();
        const database = readDatabaseSettings(process.env);
        if (database.type === 'postgres' && database.migrationsRun) {
          await runMigrationsLocked(dataSource, database);
        }
        return dataSource;
      },
    }),
    RealtimeModule,
    EngineModule,
    AuthModule,
    UsersModule,
    RankingModule,
    GamesModule,
    RoomsModule,
    TournamentsModule,
    AccountsModule,
  ],
  controllers: [HealthController, PrivacyController],
})
export class AppModule {}
