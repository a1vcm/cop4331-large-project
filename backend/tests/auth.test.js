const request = require('supertest');
const mongoose = require('mongoose');
const { app, dbReady } = require('../app');
const User = require('../collections/User');

const testEmail = 'ci-auth-test@example.com';

beforeAll(async () => {
  await dbReady;
  await User.deleteOne({ email: testEmail });
});

afterAll(async () => {
  await User.deleteOne({ email: testEmail });
  await mongoose.connection.close();
});

describe('POST /api/auth/register', () => {
  it('registers a new user and returns a token', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'ci-tester',
      email: testEmail,
      password: 'Sup3rSecret!',
    });

    expect(res.status).toBe(201);
    expect(res.body.email).toBe(testEmail);
    expect(res.body.token).toBeDefined();
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

describe('POST /api/auth/login', () => {
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
