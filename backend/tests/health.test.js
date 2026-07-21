// // original health test
// const request = require('supertest');
// const { app, client } = require('../app');

// afterAll(async () => {
//   await client.close();
// });

// describe('GET /api/health', () => {
//   it('returns 200 with status ok when MongoDB is reachable', async () => {
//     const res = await request(app).get('/api/health');

//     expect(res.status).toBe(200);
//     expect(res.body.status).toBe('ok');
//   });
// });

// UNIT TESTING
const request = require('supertest');
const app = require('../app'); // Import app directly

describe('GET /api/health', () => {
  it('returns 200 with status ok', async () => {
    const res = await request(app).get('/api/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
