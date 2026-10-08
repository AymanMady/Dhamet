import { Global, Module, OnApplicationShutdown } from '@nestjs/common';
import { AppConfig, appConfig } from '../config/app.config';
import { directConnection } from '../database/connection';
import { LocalRealtimeBus, PostgresRealtimeBus, RealtimeBus } from './realtime-bus';
import { TransactionRunner } from './transactions';

/**
 * What the instances of the server share besides the database tables:
 * locked transactions and the messages between instances.
 */
@Global()
@Module({
  providers: [
    {
      provide: RealtimeBus,
      inject: [appConfig.KEY],
      useFactory: (settings: AppConfig): RealtimeBus =>
        settings.database.type === 'postgres'
          ? new PostgresRealtimeBus(directConnection(settings.database))
          : new LocalRealtimeBus(),
    },
    TransactionRunner,
  ],
  exports: [RealtimeBus, TransactionRunner],
})
export class RealtimeModule implements OnApplicationShutdown {
  constructor(private readonly bus: RealtimeBus) {}

  async onApplicationShutdown(): Promise<void> {
    await this.bus.close();
  }
}
