import { Client } from 'pg';
import { DataSource } from 'typeorm';
import { DatabaseConfig } from '../config/app.config';
import { directConnection } from './connection';

/**
 * Runs the pending migrations of [dataSource] under a PostgreSQL session
 * lock: when several instances start at once (a new deploy on Vercel), one
 * migrates while the others wait, then find nothing left to do.
 */
export async function runMigrationsLocked(
  dataSource: DataSource,
  config: Extract<DatabaseConfig, { type: 'postgres' }>,
): Promise<void> {
  const lock = new Client(directConnection(config));
  await lock.connect();
  try {
    await lock.query('SELECT pg_advisory_lock(hashtextextended($1, 0))', ['dhamet:migrations']);
    await dataSource.runMigrations({ transaction: 'each' });
  } finally {
    // Ending the session releases the lock.
    await lock.end();
  }
}
