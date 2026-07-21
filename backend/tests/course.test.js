const request = require('supertest');
const app = require('../app');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

// Load Course model
const Course = mongoose.model('Course');

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

beforeEach(async () => {
  // Clear course collection before each test to guarantee isolation
  await Course.deleteMany({});
});

describe('GET /api/courses', () => {
  it('should return an empty list when no courses exist', async () => {
    const res = await request(app).get('/api/courses');

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(0);
  });

  it('should return all courses in the catalog', async () => {
    // Seed initial test data
    await Course.create([
      { course_code: 'COP3502', title: 'Computer Science I', department: 'CS' },
      { course_code: 'EEL3123', title: 'Networks and Systems', department: 'ECE' }
    ]);

    const res = await request(app).get('/api/courses');

    expect(res.statusCode).toBe(200);
    expect(res.body.length).toBe(2);
    expect(res.body[0]).toHaveProperty('course_code');
  });
});

describe('POST /api/courses', () => {
  it('should create a new course with valid data', async () => {
    const courseData = {
      course_code: 'COP3330',
      title: 'Object Oriented Programming',
      department: 'CS'
    };

    const res = await request(app)
      .post('/api/courses')
      .send(courseData);

    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('_id');
    expect(res.body.course_code).toBe('COP3330');

    // Verify it actually saved to the in-memory database
    const dbCourse = await Course.findOne({ course_code: 'COP3330' });
    expect(dbCourse).not.toBeNull();
  });

  it('should return 400 if required fields are missing', async () => {
    const res = await request(app)
      .post('/api/courses')
      .send({ department: 'CS' }); // Missing course_code and title

    expect(res.statusCode).toBe(400);
  });
});

describe('GET /api/courses/:id', () => {
  it('should return course details for a valid ID', async () => {
    const newCourse = await Course.create({
      course_code: 'EEL4768',
      title: 'Computer Architecture',
      department: 'ECE'
    });

    const res = await request(app).get(`/api/courses/${newCourse._id}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.course_code).toBe('EEL4768');
  });

  it('should return 404 if course ID does not exist', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app).get(`/api/courses/${fakeId}`);

    expect(res.statusCode).toBe(404);
  });
});