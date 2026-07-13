const Course = require('../collections/Course');

function escapeRegExp(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// GET /api/courses?q=search+term
// Uses a case-insensitive substring match (not the $text index) so partial
// course numbers like "4331" match "COP4331", which $text can't do since it
// only matches whole tokens. The query is regex-escaped since it's raw user
// input going straight into $regex.
async function getCourses(req, res) {
  try {
    const { q } = req.query;
    const filter = q
      ? {
          $or: [
            { course_code: { $regex: escapeRegExp(q), $options: 'i' } },
            { title: { $regex: escapeRegExp(q), $options: 'i' } },
          ],
        }
      : {};
    const courses = await Course.find(filter).limit(100);
    res.json(courses);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch courses', error: err.message });
  }
}

// GET /api/courses/:id
async function getCourseById(req, res) {
  try {
    const course = await Course.findById(req.params.id);
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    res.json(course);
  } catch (err) {
    res.status(400).json({ message: 'Invalid course id', error: err.message });
  }
}

// POST /api/courses
async function createCourse(req, res) {
  try {
    const { course_code, title, department, credits } = req.body;
    if (!course_code || !title) {
      return res.status(400).json({ message: 'course_code and title are required' });
    }

    const course = await Course.create({ course_code, title, department, credits });
    res.status(201).json(course);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'A course with that course_code already exists' });
    }
    res.status(400).json({ message: 'Invalid course data', error: err.message });
  }
}

module.exports = { getCourses, getCourseById, createCourse };
