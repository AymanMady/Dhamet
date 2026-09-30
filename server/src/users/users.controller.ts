import { Controller, Get, Param, ParseUUIDPipe, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from './user.entity';
import { toUserView, UserView } from './user.view';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: User): UserView {
    return toUserView(user);
  }

  @Get(':id')
  async profile(@Param('id', ParseUUIDPipe) id: string): Promise<UserView> {
    return toUserView(await this.users.getById(id));
  }
}
