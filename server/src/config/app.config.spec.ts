import { readSettings } from './app.config';

describe('readSettings', () => {
  it('has development defaults', () => {
    const settings = readSettings({});
    expect(settings).toMatchObject({
      production: false,
      port: 3000,
      reconnectGraceSeconds: 60,
      corsOrigins: true,
      authThrottle: { ttlSeconds: 60, limit: 20 },
      trustProxy: false,
    });
    expect(settings.jwt.secret).toEqual(expect.any(String));
    expect(settings.database).toMatchObject({ type: 'postgres', port: 5436, migrationsRun: true });
  });

  it('requires JWT_SECRET in production', () => {
    expect(() => readSettings({ NODE_ENV: 'production' })).toThrow(/JWT_SECRET/);
    expect(() => readSettings({ NODE_ENV: 'production', JWT_SECRET: '' })).toThrow(/JWT_SECRET/);
    expect(readSettings({ NODE_ENV: 'production', JWT_SECRET: 's' }).jwt.secret).toBe('s');
  });

  it('reads the database, grace period and CORS settings', () => {
    const settings = readSettings({
      DATABASE_URL: 'postgres://u:p@db:5432/x',
      RECONNECT_GRACE_SECONDS: '1.5',
      CORS_ORIGINS: 'https://a.example, https://b.example',
    });
    expect(settings.database).toMatchObject({ url: 'postgres://u:p@db:5432/x' });
    expect(settings.reconnectGraceSeconds).toBe(1.5);
    expect(settings.corsOrigins).toEqual(['https://a.example', 'https://b.example']);
    expect(readSettings({ DB_TYPE: 'sqljs' }).database).toEqual({ type: 'sqljs' });
  });

  it('reads TRUST_PROXY as a flag, a number of hops or a list of proxies', () => {
    const trustProxy = (value: string) => readSettings({ TRUST_PROXY: value }).trustProxy;
    expect(trustProxy('')).toBe(false);
    expect(trustProxy('false')).toBe(false);
    expect(trustProxy('true')).toBe(true);
    expect(trustProxy('3')).toBe(3);
    expect(trustProxy('loopback, 10.0.0.0/8')).toBe('loopback, 10.0.0.0/8');
  });

  it.each([
    ['PORT', 'abc'],
    ['PORT', '3000.5'],
    ['RECONNECT_GRACE_SECONDS', '0'],
    ['DB_TYPE', 'mysql'],
    ['DB_SYNCHRONIZE', 'maybe'],
    ['TRUST_PROXY', '11'],
  ])('rejects %s=%s', (name, value) => {
    expect(() => readSettings({ [name]: value })).toThrow();
  });
});
