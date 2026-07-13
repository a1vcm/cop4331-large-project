const request = require('supertest');
const mongoose = require('mongoose');
const { app, dbReady } = require('../app');
const User = require('../collections/User');

const testEmail = 'ci-auth-test@example.com';

async function getStoredUser() {
  return User.findOne({ email: testEmail });
}

beforeAll(async () => {
  await dbReady;
  await User.deleteOne({ email: testEmail });
});

afterAll(async () => {
  await User.deleteOne({ email: testEmail });
  await mongoose.connection.close();
});

describe('POST /api/auth/register', () => {
  it('registers a new unverified user and does not return a token', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'ci-tester',
      email: testEmail,
      password: 'Sup3rSecret!',
    });

    expect(res.status).toBe(201);
    expect(res.body.email).toBe(testEmail);
    expect(res.body.token).toBeUndefined();

    const stored = await getStoredUser();
    expect(stored.isVerified).toBe(false);
    expect(stored.verificationCode).toMatch(/^\d{6}$/);
  });

  it('rejects a duplicate email', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'ci-tester-2',
      email: testEmail,
      password: 'Sup3rSecret!',
    });

    expect(res.status).toBe(409);
  });

  it('rejects a missing password', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'no-password',
      email: 'no-password@example.com',
    });

    expect(res.status).toBe(400);
  });
});

describe('POST /api/auth/login before verification', () => {
  it('rejects login with 403 and unverified flag', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: testEmail,
      password: 'Sup3rSecret!',
    });

    expect(res.status).toBe(403);
    expect(res.body.unverified).toBe(true);
  });
});

describe('POST /api/auth/verify-email', () => {
  it('rejects an incorrect code', async () => {
    const res = await request(app).post('/api/auth/verify-email').send({
      email: testEmail,
      code: '000000',
    });

    expect(res.status).toBe(400);
  });

  it('verifies with the correct code and returns a token', async () => {
    const stored = await getStoredUser();
    const res = await request(app).post('/api/auth/verify-email').send({
      email: testEmail,
      code: stored.verificationCode,
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();

    const updated = await getStoredUser();
    expect(updated.isVerified).toBe(true);
    expect(updated.verificationCode).toBeUndefined();
  });

  it('is idempotent for an already-verified user', async () => {
    const res = await request(app).post('/api/auth/verify-email').send({
      email: testEmail,
      code: '000000',
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
  });
});

describe('POST /api/auth/login after verification', () => {
  it('logs in with correct credentials', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: testEmail,
      password: 'Sup3rSecret!',
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
  });

  it('rejects an incorrect password', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: testEmail,
      password: 'wrong-password',
    });

    expect(res.status).toBe(401);
  });

  it('rejects an unknown email', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'nobody@example.com',
      password: 'whatever',
    });

    expect(res.status).toBe(401);
  });
});

describe('POST /api/auth/forgot-password and /api/auth/reset-password', () => {
  it('returns a generic message for both known and unknown emails', async () => {
    const known = await request(app).post('/api/auth/forgot-password').send({ email: testEmail });
    const unknown = await request(app).post('/api/auth/forgot-password').send({ email: 'nobody@example.com' });

    expect(known.status).toBe(200);
    expect(unknown.status).toBe(200);
    expect(known.body.message).toBe(unknown.body.message);
  });

  it('rejects an incorrect reset code', async () => {
    const res = await request(app).post('/api/auth/reset-password').send({
      email: testEmail,
      code: '000000',
      newPassword: 'NewPassword123!',
    });

    expect(res.status).toBe(400);
  });

  it('resets the password with the correct code and allows login with it', async () => {
    const stored = await getStoredUser();
    const resetRes = await request(app).post('/api/auth/reset-password').send({
      email: testEmail,
      code: stored.passwordResetCode,
      newPassword: 'NewPassword123!',
    });

    expect(resetRes.status).toBe(200);

    const oldLogin = await request(app).post('/api/auth/login').send({
      email: testEmail,
      password: 'Sup3rSecret!',
    });
    expect(oldLogin.status).toBe(401);

    const newLogin = await request(app).post('/api/auth/login').send({
      email: testEmail,
      password: 'NewPassword123!',
    });
    expect(newLogin.status).toBe(200);
    expect(newLogin.body.token).toBeDefined();
  });
});
