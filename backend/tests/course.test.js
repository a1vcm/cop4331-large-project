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

  it('finds a course by a partial course_code substring', async () => {
    const res = await request(app).get('/api/courses').query({ q: '1010' });

    expect(res.status).toBe(200);
    expect(res.body.some((c) => c.course_code === testCode)).toBe(true);
  });

  it('does not treat the query as a regex (special characters are literal)', async () => {
    const res = await request(app).get('/api/courses').query({ q: '(unmatched' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
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

  it('updates a course', async () => {
    const created = await Course.findOne({ course_code: testCode });
    const res = await request(app).put(`/api/courses/${created._id}`).send({
      course_code: testCode,
      title: 'CI Test Course (updated)',
      department: 'COP',
      credits: 4,
    });

    expect(res.status).toBe(200);
    expect(res.body.title).toBe('CI Test Course (updated)');
    expect(res.body.credits).toBe(4);
  });

  it('returns 404 updating a nonexistent course', async () => {
    const res = await request(app)
      .put('/api/courses/000000000000000000000000')
      .send({ title: 'Nope' });

    expect(res.status).toBe(404);
  });

  it('deletes a course', async () => {
    const created = await Course.findOne({ course_code: testCode });
    const res = await request(app).delete(`/api/courses/${created._id}`);

    expect(res.status).toBe(200);

    const gone = await Course.findById(created._id);
    expect(gone).toBeNull();
  });

  it('returns 404 deleting a nonexistent course', async () => {
    const res = await request(app).delete('/api/courses/000000000000000000000000');

    expect(res.status).toBe(404);
  });
});
