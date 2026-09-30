import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GamesModule } from '../games/games.module';
import { UsersModule } from '../users/users.module';
import { ConnectionRegistry } from './connection-registry';
import { GameplayService } from './gameplay.service';
import { Room } from './room.entity';
import { RoomStore } from './room-store';
import { RoomsGateway } from './rooms.gateway';
import { RoomsService } from './rooms.service';

@Module({
  imports: [TypeOrmModule.forFeature([Room]), UsersModule, GamesModule],
  providers: [RoomStore, ConnectionRegistry, GameplayService, RoomsService, RoomsGateway],
  exports: [RoomsService, GameplayService],
})
export class RoomsModule {}
