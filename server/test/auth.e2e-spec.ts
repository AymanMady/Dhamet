import { TestApp } from './support/test-app';

describe('Auth and users (REST)', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await TestApp.start();
  });

  afterAll(async () => {
    await t.stop();
  });

  it('registers an account: 201 {token, user}', async () => {
    const response = await t.http
      .post('/api/auth/register')
      .send({ username: 'Amina_1', password: 'password123' })
      .expect(201);
    expect(response.body).toEqual({
      token: expect.any(String),
      user: {
        id: expect.stringMatching(/^[0-9a-f-]{36}$/),
        username: 'Amina_1',
        isGuest: false,
        rating: 1200,
        wins: 0,
        losses: 0,
        draws: 0,
        gamesPlayed: 0,
        createdAt: expect.any(String),
      },
    });
    expect(JSON.stringify(response.body)).not.toContain('password');
  });

  it('refuses a username already taken, whatever its case: 409', async () => {
    await t.http
      .post('/api/auth/register')
      .send({ username: 'amina_1', password: 'another-password' })
      .expect(409);
    await t.http.post('/api/auth/guest').send({ username: 'AMINA_1' }).expect(409);
  });

  it.each([
    [{ username: 'ab', password: 'password123' }],
    [{ username: 'a'.repeat(21), password: 'password123' }],
    [{ username: 'bad-name', password: 'password123' }],
    [{ username: 'good_name', password: 'short' }],
    [{ username: 'good_name' }],
    [{}],
  ])('refuses invalid data: 400 (%j)', async (body) => {
    const response = await t.http.post('/api/auth/register').send(body).expect(400);
    expect(response.body).toMatchObject({ statusCode: 400, error: 'Bad Request' });
  });

  it('logs in: 200 {token, user}', async () => {
    const response = await t.http
      .post('/api/auth/login')
      .send({ username: 'AMINA_1', password: 'password123' })
      .expect(200);
    expect(response.body.user.username).toBe('Amina_1');
    expect(response.body.token).toEqual(expect.any(String));
  });

  it('refuses bad credentials: 401', async () => {
    await t.http
      .post('/api/auth/login')
      .send({ username: 'Amina_1', password: 'wrong-password' })
      .expect(401);
    await t.http
      .post('/api/auth/login')
      .send({ username: 'nobody_here', password: 'password123' })
      .expect(401);
  });

  it('creates guests: 201, named invite_XXXX unless a name is given', async () => {
    const anonymous = await t.http.post('/api/auth/guest').send({}).expect(201);
    expect(anonymous.body.user).toMatchObject({ isGuest: true, rating: 1200 });
    expect(anonymous.body.user.username).toMatch(/^invite_[a-z0-9]{4}$/);
    const named = await t.http.post('/api/auth/guest').send({ username: 'Visitor_7' }).expect(201);
    expect(named.body.user).toMatchObject({ username: 'Visitor_7', isGuest: true });
  });

  it('never logs a guest in with a password', async () => {
    await t.http.post('/api/auth/guest').send({ username: 'guest_only' }).expect(201);
    await t.http
      .post('/api/auth/login')
      .send({ username: 'guest_only', password: 'password123' })
      .expect(401);
  });

  it('returns the current user with a token: GET /api/users/me', async () => {
    const account = await t.register('me');
    const response = await t.http
      .get('/api/users/me')
      .set('Authorization', `Bearer ${account.token}`)
      .expect(200);
    expect(response.body).toEqual(account.user);
  });

  it('requires a valid token: 401', async () => {
    await t.http.get('/api/users/me').expect(401);
    await t.http.get('/api/users/me').set('Authorization', 'Bearer not-a-jwt').expect(401);
  });

  it('shows public profiles: GET /api/users/:id', async () => {
    const account = await t.register('public');
    const response = await t.http.get(`/api/users/${account.user.id}`).expect(200);
    expect(response.body).toEqual(account.user);
    await t.http.get('/api/users/00000000-0000-4000-8000-000000000000').expect(404);
    await t.http.get('/api/users/not-a-uuid').expect(400);
  });
});
