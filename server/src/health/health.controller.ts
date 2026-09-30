import { Controller, Get } from '@nestjs/common';

/**
 * Health check of the hosting platform (Render: `healthCheckPath`), which
 * waits for it before routing traffic to a new deploy.
 *
 * It does not query the database: the server only listens once the database
 * has answered and the migrations have run, and a failing check makes the
 * host restart the instance, which would end every game held in memory.
 */
@Controller('health')
export class HealthController {
  @Get()
  check(): { status: 'ok' } {
    return { status: 'ok' };
  }
}
