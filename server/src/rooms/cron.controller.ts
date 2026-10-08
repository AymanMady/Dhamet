import {
  Controller,
  Get,
  Headers,
  Inject,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { timingSafeEqual } from 'node:crypto';
import { AppConfig, appConfig } from '../config/app.config';
import { RoomsService } from './rooms.service';

/** Rooms settled by one call, at most. */
const SWEEP_LIMIT = 500;

/**
 * `GET /api/cron/sweep`, called by the scheduler of the host (Vercel Cron
 * Jobs, `vercel.json`) with `Authorization: Bearer <CRON_SECRET>`. It
 * settles the rooms whose deadline passed while nobody was connected to
 * watch them: rooms left empty, forfeits of two absent players.
 */
@Controller('cron')
export class CronController {
  constructor(
    private readonly rooms: RoomsService,
    @Inject(appConfig.KEY) private readonly settings: AppConfig,
  ) {}

  @Get('sweep')
  async sweep(@Headers('authorization') authorization?: string): Promise<{ settled: number }> {
    const secret = this.settings.cronSecret;
    if (!secret) throw new NotFoundException();
    const expected = Buffer.from(`Bearer ${secret}`);
    const given = Buffer.from(authorization ?? '');
    if (given.length !== expected.length || !timingSafeEqual(given, expected)) {
      throw new UnauthorizedException();
    }
    return { settled: await this.rooms.sweep(SWEEP_LIMIT) };
  }
}
