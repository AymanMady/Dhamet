import { TestApp } from './support/test-app';

// Read when the app starts: the chain of proxies in front of the server on
// Render (Cloudflare, load balancer, internal proxy) and a low auth rate limit.
process.env.TRUST_PROXY = '3';
process.env.AUTH_THROTTLE_LIMIT = '2';
process.env.CRON_SECRET = 'cron-secret';
process.env.CONTACT_EMAIL = 'dhametna@example.net';

describe('Deployment behind a reverse proxy', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await TestApp.start();
  });

  afterAll(async () => {
    await t.stop();
  });

  it('answers the health check: 200 {status: "ok"}', async () => {
    await t.http.get('/api/health').expect(200, { status: 'ok' });
  });

  it('publishes the privacy policy, with the contact address: GET /confidentialite', async () => {
    const page = await t.http.get('/confidentialite').expect(200);
    expect(page.headers['content-type']).toMatch(/^text\/html/);
    expect(page.text).toContain('id="suppression"');
    expect(page.text).toContain('mailto:dhametna@example.net');
    expect(page.text).not.toContain('contact@example.org');
    await t.http.get('/privacy').expect(200);
    await t.http.get('/api/confidentialite').expect(404);
  });

  it('runs the scheduled sweep only for the scheduler: GET /api/cron/sweep', async () => {
    await t.http.get('/api/cron/sweep').expect(401);
    await t.http.get('/api/cron/sweep').set('Authorization', 'Bearer wrong').expect(401);
    await t.http
      .get('/api/cron/sweep')
      .set('Authorization', 'Bearer cron-secret')
      .expect(200, { settled: 0 });
  });

  it('rate-limits /api/auth per client address, read through the proxies', async () => {
    // Each proxy appends the address it received the request from.
    const guest = (...forwardedFor: string[]) =>
      t.http
        .post('/api/auth/guest')
        .set('X-Forwarded-For', [...forwardedFor, '172.71.0.1', '10.226.0.1'].join(', '))
        .send({});
    await guest('81.0.0.1').expect(201);
    await guest('81.0.0.1').expect(201);
    await guest('81.0.0.1').expect(429);
    // Another client keeps its own quota…
    await guest('81.0.0.2').expect(201);
    // …and an address forged by the caller does not reset theirs.
    await guest('1.2.3.4', '81.0.0.1').expect(429);
  });
});
