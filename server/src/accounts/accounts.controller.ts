import { Controller, Delete, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../users/user.entity';
import { AccountsService } from './accounts.service';

@Controller('users')
export class AccountsController {
  constructor(private readonly accounts: AccountsService) {}

  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  delete(@CurrentUser() user: User): Promise<void> {
    return this.accounts.delete(user);
  }
}
