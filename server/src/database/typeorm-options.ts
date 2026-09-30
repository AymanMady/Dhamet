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
    migrations: [join(__dirname, 'migrations', '*.js')],
    migrationsRun: config.migrationsRun,
    synchronize: config.synchronize,
    uuidExtension: 'pgcrypto',
  };
}
