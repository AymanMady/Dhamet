import { Module } from '@nestjs/common';
import { RoomsModule } from '../rooms/rooms.module';
import { TournamentsModule } from '../tournaments/tournaments.module';
import { UsersModule } from '../users/users.module';
import { AccountsController } from './accounts.controller';
import { AccountsService } from './accounts.service';

/** `DELETE /api/users/me`: above rooms and tournaments, which it empties first. */
@Module({
  imports: [UsersModule, RoomsModule, TournamentsModule],
  controllers: [AccountsController],
  providers: [AccountsService],
})
export class AccountsModule {}
