import { Injectable } from '@nestjs/common';
import { RoomsService } from '../rooms/rooms.service';
import { TournamentsService } from '../tournaments/tournaments.service';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';

/**
 * Account deletion (required by the stores). The row of a deleted account
 * is kept, anonymized, so that the games, ratings and tournaments of the
 * other players stay whole.
 */
@Injectable()
export class AccountsService {
  constructor(
    private readonly users: UsersService,
    private readonly rooms: RoomsService,
    private readonly tournaments: TournamentsService,
  ) {}

  /**
   * Deletes the account of [user]: it leaves its rooms (resigning a game in
   * progress) and its tournaments, then is anonymized and disconnected.
   * Everything before the anonymization can run again, so a failure leaves
   * an account whose owner can simply retry.
   */
  async delete(user: User): Promise<void> {
    await this.rooms.leaveAll(user.id);
    await this.tournaments.withdraw(user.id);
    const deleted = await this.users.delete(user.id);
    await this.rooms.accountDeleted(deleted);
  }
}
