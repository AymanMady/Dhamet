// Environment of the e2e tests: in-memory database, short reconnection grace.
process.env.NODE_ENV = 'test';
process.env.DB_TYPE = 'sqljs';
process.env.JWT_SECRET = 'e2e-secret';
process.env.RECONNECT_GRACE_SECONDS = '1';
process.env.AUTH_THROTTLE_LIMIT = '10000';
