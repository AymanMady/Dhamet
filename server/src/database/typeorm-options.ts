import { join } from 'node:path';
import { DataSourceOptions } from 'typeorm';
import { DatabaseConfig } from '../config/app.config';
import { ENTITIES } from './entities';

/**
 * PostgreSQL in production and development, with the schema managed by the
 * migrations in ./migrations; in-memory sql.js (schema synchronized) for
 * automated tests.
 */
export function typeOrmOptions(config: DatabaseConfig): DataSourceOptions {
  if (config.type === 'sqljs') {
    return { type: 'sqljs', entities: ENTITIES, synchronize: true };
  }
  return {
    type: 'postgres',
    url: config.url,
    host: config.host,
    port: config.port,
    username: config.username,
    password: config.password,
    database: config.database,
    entities: ENTITIES,
    // .js once built; .ts when the tests run the sources.
    migrations: [join(__dirname, 'migrations', '*.{js,ts}')],
    // Run by MigrationRunner, under a lock: several instances may start at once.
    migrationsRun: false,
    synchronize: config.synchronize,
    uuidExtension: 'pgcrypto',
    extra: { max: config.poolSize },
  };
}
