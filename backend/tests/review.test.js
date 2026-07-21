const request = require('supertest');
const app = require('../app');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const { MongoMemoryServer } = require('mongodb-memory-server');

const Course = mongoose.model('Course');
const Review = mongoose.model('Review');
const User = mongoose.model('User');

let mongoServer;
let testUser;
let testCourse;
let authToken;

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

beforeEach(async () => {
  await Course.deleteMany({});
  await Review.deleteMany({});
  await User.deleteMany({});

  // 1. Create test user
  testUser = await User.create({
    username: 'knightReviewer',
    email: 'reviewer@ucf.edu',
    passwordHash: '$2b$10$e8N8YJ0...mockHashedPassword',
    isVerified: true
  });

  // 2. Generate JWT for authorized requests
  const secret = process.env.JWT_SECRET || 'testsecret';
  authToken = jwt.sign({ id: testUser._id }, secret, { expiresIn: '1h' });

  // 3. Create test course
  testCourse = await Course.create({
    course_code: 'COP3502',
    title: 'Computer Science I',
    department: 'CS'
  });
});

describe('GET /api/reviews/course/:courseId', () => {
  it('should return empty list when no reviews exist for the course', async () => {
    const res = await request(app).get(`/api/reviews/course/${testCourse._id}`);

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(0);
  });

  it('should fetch all reviews for a course', async () => {
    // Included courseId, quality, and difficulty
    await Review.create({
      courseId: testCourse._id,
      user: testUser._id,
      quality: 5,
      difficulty: 3,
      comment: 'Great course, challenging exams!'
    });

    const res = await request(app).get(`/api/reviews/course/${testCourse._id}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.length).toBe(1);
  });
});

describe('POST /api/reviews', () => {
  it('should return 401 if request is unauthenticated', async () => {
    const res = await request(app)
      .post('/api/reviews')
      .send({
        courseId: testCourse._id,
        quality: 5,
        difficulty: 3,
        comment: 'Unauthenticated test'
      });

    expect(res.statusCode).toBe(401);
  });

  it('should create a review when authorized token is provided', async () => {
    const reviewPayload = {
      courseId: testCourse._id,
      quality: 4,
      difficulty: 3,
      comment: 'Solid professor and clear rubric.'
    };

    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${authToken}`)
      .send(reviewPayload);

    expect([200, 201]).toContain(res.statusCode);
    expect(res.body).toHaveProperty('_id');
  });
});

describe('DELETE /api/reviews/:id', () => {
  it('should delete a review when authorized token is provided', async () => {
    const review = await Review.create({
      courseId: testCourse._id,
      userId: testUser._id, // Updated to userId to match courseId convention
      user: testUser._id,   // Set both to cover all bases
      quality: 3,
      difficulty: 4,
      comment: 'Average difficulty.'
    });

    const res = await request(app)
      .delete(`/api/reviews/${review._id}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect([200, 204]).toContain(res.statusCode);

    const dbCheck = await Review.findById(review._id);
    expect(dbCheck).toBeNull();
  });
});