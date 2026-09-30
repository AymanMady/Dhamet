import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppConfig, appConfig } from './config/app.config';
import { DhametWsAdapter } from './rooms/ws-adapter';

/** HTTP and WebSocket setup shared by `main.ts` and the e2e tests. */
export function configureApp(app: INestApplication): void {
  const settings = app.get<AppConfig>(appConfig.KEY);
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useWebSocketAdapter(new DhametWsAdapter(app));
  app.enableCors({ origin: settings.corsOrigins });
}
