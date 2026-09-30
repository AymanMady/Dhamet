// DataSource for the TypeORM CLI (migrations), used from the compiled
// output: `npm run build && npm run migration:run`.
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { readSettings } from '../config/app.config';
import { typeOrmOptions } from './typeorm-options';

process.env.TZ = 'UTC';

export default new DataSource(typeOrmOptions(readSettings(process.env).database));
