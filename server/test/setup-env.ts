// Environment of the e2e tests: in-memory database, short reconnection grace.
process.env.NODE_ENV = 'test';
process.env.DB_TYPE = 'sqljs';
process.env.JWT_SECRET = 'e2e-secret';
process.env.RECONNECT_GRACE_SECONDS = '1';
// The other players hear of a disconnection at once, as before the notice delay.
process.env.DISCONNECT_NOTICE_SECONDS = '0';
process.env.AUTH_THROTTLE_LIMIT = '10000';
