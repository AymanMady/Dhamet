import { Module } from '@nestjs/common';
import { GamesModule } from '../games/games.module';
import { ConnectionRegistry } from './connection-registry';
import { CronController } from './cron.controller';
import { GameplayService } from './gameplay.service';
import { RoomDeadlines } from './room-deadlines';
import { RoomStore } from './room-store';
import { RoomsGateway } from './rooms.gateway';
import { RoomsService } from './rooms.service';

@Module({
  imports: [GamesModule],
  controllers: [CronController],
  providers: [
    RoomStore,
    ConnectionRegistry,
    GameplayService,
    RoomsService,
    RoomDeadlines,
    RoomsGateway,
  ],
  exports: [RoomsService, GameplayService],
})
export class RoomsModule {}
