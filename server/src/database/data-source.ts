// DataSource for the TypeORM CLI (migrations), used from the compiled
// output: `npm run build && npm run migration:run`.
import 'reflect-metadata';
import { existsSync } from 'node:fs';
import { DataSource } from 'typeorm';
import { readDatabaseSettings } from '../config/app.config';
import { typeOrmOptions } from './typeorm-options';

process.env.TZ = 'UTC';
// Like the app (ConfigModule), read .env without overriding the environment.
if (existsSync('.env')) process.loadEnvFile('.env');

export default new DataSource(typeOrmOptions(readDatabaseSettings(process.env)));
