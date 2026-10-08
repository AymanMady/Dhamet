import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppConfig, appConfig } from './config/app.config';
import { PRIVACY_PATHS } from './legal/privacy.controller';
import { DhametWsAdapter } from './rooms/ws-adapter';

/** HTTP and WebSocket setup shared by `main.ts` and the e2e tests. */
export function configureApp(app: NestExpressApplication): void {
  const settings = app.get<AppConfig>(appConfig.KEY);
  app.set('trust proxy', settings.trustProxy);
  // The privacy policy is a public page, not part of the API.
  app.setGlobalPrefix('api', { exclude: PRIVACY_PATHS });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useWebSocketAdapter(new DhametWsAdapter(app));
  app.enableCors({ origin: settings.corsOrigins });
}
