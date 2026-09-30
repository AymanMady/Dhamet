import { ConfigType, registerAs } from '@nestjs/config';

export type DatabaseConfig =
  | { type: 'sqljs' }
  | {
      type: 'postgres';
      url?: string;
      host: string;
      port: number;
      username: string;
      password: string;
      database: string;
      synchronize: boolean;
      migrationsRun: boolean;
    };

export interface Settings {
  production: boolean;
  port: number;
  jwt: { secret: string; expiresInSeconds: number };
  database: DatabaseConfig;
  /** How long a player may stay disconnected from a game before forfeiting. */
  reconnectGraceSeconds: number;
  /** Allowed CORS origins; `true` reflects any origin. */
  corsOrigins: string[] | true;
  /** Rate limit of the auth routes: `limit` requests per `ttlSeconds` and client. */
  authThrottle: { ttlSeconds: number; limit: number };
}

type Env = Record<string, string | undefined>;

const DEV_JWT_SECRET = 'dhamet-dev-secret-do-not-use-in-production';

/** Reads and checks the settings from [env]. Throws on invalid values. */
export function readSettings(env: Env): Settings {
  const production = env.NODE_ENV === 'production';
  const secret = env.JWT_SECRET ?? (production ? undefined : DEV_JWT_SECRET);
  if (!secret) throw new Error('JWT_SECRET is required when NODE_ENV=production');
  const cors = env.CORS_ORIGINS?.trim();
  return {
    production,
    port: number(env, 'PORT', 3000, { min: 0, max: 65535, integer: true }),
    jwt: {
      secret,
      expiresInSeconds: number(env, 'JWT_EXPIRES_IN_SECONDS', 30 * 86400, {
        min: 60,
        max: 365 * 86400,
        integer: true,
      }),
    },
    database: readDatabase(env),
    reconnectGraceSeconds: number(env, 'RECONNECT_GRACE_SECONDS', 60, { min: 0.1, max: 3600 }),
    corsOrigins:
      !cors || cors === '*'
        ? true
        : cors
            .split(',')
            .map((origin) => origin.trim())
            .filter(Boolean),
    authThrottle: {
      ttlSeconds: number(env, 'AUTH_THROTTLE_TTL_SECONDS', 60, { min: 1, max: 86400 }),
      limit: number(env, 'AUTH_THROTTLE_LIMIT', 20, { min: 1, max: 1_000_000, integer: true }),
    },
  };
}

function readDatabase(env: Env): DatabaseConfig {
  const type = env.DB_TYPE ?? 'postgres';
  if (type === 'sqljs') return { type };
  if (type !== 'postgres') throw new Error(`DB_TYPE must be "postgres" or "sqljs", not "${type}"`);
  return {
    type,
    url: env.DATABASE_URL || undefined,
    host: env.DB_HOST ?? 'localhost',
    port: number(env, 'DB_PORT', 5432, { min: 1, max: 65535, integer: true }),
    username: env.DB_USER ?? 'dhamet',
    password: env.DB_PASSWORD ?? 'dhamet',
    database: env.DB_NAME ?? 'dhamet',
    synchronize: flag(env, 'DB_SYNCHRONIZE', false),
    migrationsRun: flag(env, 'DB_MIGRATIONS_RUN', true),
  };
}

function number(
  env: Env,
  name: string,
  fallback: number,
  range: { min: number; max: number; integer?: boolean },
): number {
  const raw = env[name];
  if (raw === undefined || raw === '') return fallback;
  const value = Number(raw);
  if (
    !Number.isFinite(value) ||
    value < range.min ||
    value > range.max ||
    (range.integer && !Number.isInteger(value))
  ) {
    throw new Error(`${name} must be a number between ${range.min} and ${range.max}`);
  }
  return value;
}

function flag(env: Env, name: string, fallback: boolean): boolean {
  const raw = env[name];
  if (raw === undefined || raw === '') return fallback;
  if (raw === 'true' || raw === '1') return true;
  if (raw === 'false' || raw === '0') return false;
  throw new Error(`${name} must be true or false`);
}

/** Injectable settings: `@Inject(appConfig.KEY) settings: AppConfig`. */
export const appConfig = registerAs('app', () => readSettings(process.env));

export type AppConfig = ConfigType<typeof appConfig>;
