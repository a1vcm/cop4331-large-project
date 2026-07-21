const request = require('supertest');
const app = require('../app'); // Path to your Express app
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
  await mongoServer.stop();
});

describe('POST /api/auth/register', () => {
  it('should return 400 if required fields are missing', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: 'student@ucf.edu' }); // Missing username and password

    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('message');
  });

  it('should register a user successfully', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'knightTester',
        email: 'tester@ucf.edu',
        password: 'Password123!'
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.email).toEqual('tester@ucf.edu');
  });
});