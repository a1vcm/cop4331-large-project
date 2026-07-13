const request = require('supertest');
const mongoose = require('mongoose');
const { app, client, dbReady } = require('../app');

beforeAll(async () => {
  await dbReady;
});

afterAll(async () => {
  await client.close();
  await mongoose.connection.close();
});

describe('GET /api/health', () => {
  it('returns 200 with status ok when MongoDB is reachable', async () => {
    const res = await request(app).get('/api/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
