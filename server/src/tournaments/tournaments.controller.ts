import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../users/user.entity';
import { CreateTournamentDto } from './dto/create-tournament.dto';
import { TournamentView } from './tournament.view';
import { TournamentsService } from './tournaments.service';

@Controller('tournaments')
export class TournamentsController {
  constructor(private readonly tournaments: TournamentsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: User, @Body() dto: CreateTournamentDto): Promise<TournamentView> {
    return this.tournaments.create(user, dto);
  }

  @Get()
  list(): Promise<TournamentView[]> {
    return this.tournaments.list();
  }

  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string): Promise<TournamentView> {
    return this.tournaments.view(id);
  }

  @Post(':id/join')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  join(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string): Promise<TournamentView> {
    return this.tournaments.join(user, id);
  }

  @Post(':id/start')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  start(
    @CurrentUser() user: User,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<TournamentView> {
    return this.tournaments.start(user, id);
  }
}
