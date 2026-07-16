const request = require('supertest');
const mongoose = require('mongoose');
const { app, dbReady } = require('../app');
const User = require('../collections/User');
const Course = require('../collections/Course');
const Review = require('../collections/Review');

const testEmail = 'ci-review-test@example.com';
const otherEmail = 'ci-review-test-2@example.com';
const courseCode = 'CI-TEST-REVIEW-1010';

let token;
let otherToken;
let courseId;
let reviewId;

async function registerAndVerify(email, username) {
  await request(app).post('/api/auth/register').send({
    username,
    email,
    password: 'Sup3rSecret!',
  });
  const user = await User.findOne({ email });
  const res = await request(app).post('/api/auth/verify-email').send({
    email,
    code: user.verificationCode,
  });
  return res.body.token;
}

beforeAll(async () => {
  await dbReady;
  await User.deleteMany({ email: { $in: [testEmail, otherEmail] } });
  await Course.deleteOne({ course_code: courseCode });

  token = await registerAndVerify(testEmail, 'ci-review-tester');
  otherToken = await registerAndVerify(otherEmail, 'ci-review-tester-2');

  const course = await Course.create({ course_code: courseCode, title: 'CI Review Test Course' });
  courseId = course._id.toString();
});

afterAll(async () => {
  await Review.deleteMany({ courseId });
  await Course.deleteOne({ course_code: courseCode });
  await User.deleteMany({ email: { $in: [testEmail, otherEmail] } });
  await mongoose.connection.close();
});

describe('POST /api/reviews', () => {
  it('rejects an unauthenticated request', async () => {
    const res = await request(app).post('/api/reviews').send({
      courseId,
      quality: 4,
      difficulty: 3,
    });

    expect(res.status).toBe(401);
  });

  it('creates a review and updates course stats', async () => {
    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({
        courseId,
        instructor: 'Dr. Test',
        term: 'Fall 2026',
        quality: 4,
        difficulty: 2,
        comment: 'Solid class.',
      });

    expect(res.status).toBe(201);
    reviewId = res.body._id;

    const course = await Course.findById(courseId);
    expect(course.numRatings).toBe(1);
    expect(course.avgRating).toBe(4);
    expect(course.avgDifficulty).toBe(2);
  });

  it('rejects a second review from the same user for the same course', async () => {
    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ courseId, quality: 5, difficulty: 5 });

    expect(res.status).toBe(409);
  });

  it('rejects a review for a nonexistent course', async () => {
    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ courseId: '000000000000000000000000', quality: 5, difficulty: 5 });

    expect(res.status).toBe(404);
  });
});

describe('GET /api/reviews/course/:courseId', () => {
  it('lists reviews for a course without requiring auth', async () => {
    const res = await request(app).get(`/api/reviews/course/${courseId}`);

    expect(res.status).toBe(200);
    expect(res.body.some((r) => r._id === reviewId)).toBe(true);
  });
});

describe('PUT /api/reviews/:id', () => {
  it("rejects editing another user's review", async () => {
    const res = await request(app)
      .put(`/api/reviews/${reviewId}`)
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ quality: 1 });

    expect(res.status).toBe(403);
  });

  it('lets the author update their own review and recalculates stats', async () => {
    const res = await request(app)
      .put(`/api/reviews/${reviewId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ quality: 2, difficulty: 4 });

    expect(res.status).toBe(200);
    expect(res.body.quality).toBe(2);

    const course = await Course.findById(courseId);
    expect(course.avgRating).toBe(2);
    expect(course.avgDifficulty).toBe(4);
  });
});

describe('DELETE /api/reviews/:id', () => {
  it("rejects deleting another user's review", async () => {
    const res = await request(app)
      .delete(`/api/reviews/${reviewId}`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(403);
  });

  it('lets the author delete their own review and resets course stats', async () => {
    const res = await request(app)
      .delete(`/api/reviews/${reviewId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);

    const course = await Course.findById(courseId);
    expect(course.numRatings).toBe(0);
  });
});
