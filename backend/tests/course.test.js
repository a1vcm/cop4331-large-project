const request = require('supertest');
const mongoose = require('mongoose');
const { app, dbReady } = require('../app');
const Course = require('../collections/Course');

const testCode = 'CI-TEST-1010';

beforeAll(async () => {
  await dbReady;
  await Course.deleteOne({ course_code: testCode });
});

afterAll(async () => {
  await Course.deleteOne({ course_code: testCode });
  await mongoose.connection.close();
});

describe('Course endpoints', () => {
  it('creates a course', async () => {
    const res = await request(app).post('/api/courses').send({
      course_code: testCode,
      title: 'CI Test Course',
      department: 'COP',
      credits: 3,
    });

    expect(res.status).toBe(201);
    expect(res.body.course_code).toBe(testCode);
  });

  it('rejects a duplicate course_code', async () => {
    const res = await request(app).post('/api/courses').send({
      course_code: testCode,
      title: 'Duplicate',
    });

    expect(res.status).toBe(409);
  });

  it('rejects a missing title', async () => {
    const res = await request(app).post('/api/courses').send({
      course_code: 'CI-TEST-NO-TITLE',
    });

    expect(res.status).toBe(400);
  });

  it('lists courses including the created one', async () => {
    const res = await request(app).get('/api/courses');

    expect(res.status).toBe(200);
    expect(res.body.some((c) => c.course_code === testCode)).toBe(true);
  });

  it('fetches a course by id', async () => {
    const created = await Course.findOne({ course_code: testCode });
    const res = await request(app).get(`/api/courses/${created._id}`);

    expect(res.status).toBe(200);
    expect(res.body.course_code).toBe(testCode);
  });

  it('returns 404 for a nonexistent id', async () => {
    const res = await request(app).get('/api/courses/000000000000000000000000');

    expect(res.status).toBe(404);
  });
});
