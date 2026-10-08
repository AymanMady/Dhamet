import { ClientConfig } from 'pg';
import { DatabaseConfig } from '../config/app.config';

/**
 * A single connection to the database, for what a transaction pooler
 * cannot do: LISTEN, and the session lock of the migrations.
 */
export function directConnection(
  config: Extract<DatabaseConfig, { type: 'postgres' }>,
): ClientConfig {
  if (config.directUrl) return { connectionString: config.directUrl };
  return {
    host: config.host,
    port: config.port,
    user: config.username,
    password: config.password,
    database: config.database,
  };
}
