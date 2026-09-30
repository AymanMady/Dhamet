// Dates are written to and read from PostgreSQL `timestamp` columns in UTC.
process.env.TZ = 'UTC';

import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { AppConfig, appConfig } from './config/app.config';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  configureApp(app);
  app.enableShutdownHooks();
  const { port } = app.get<AppConfig>(appConfig.KEY);
  await app.listen(port);
  Logger.log(`Dhamet server listening on port ${port} (REST /api, WebSocket /ws)`, 'Bootstrap');
}

void bootstrap();
