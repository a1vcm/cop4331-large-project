const Course = require('../collections/Course');

// GET /api/courses?q=search+term
async function getCourses(req, res) {
  try {
    const { q } = req.query;
    const filter = q ? { $text: { $search: q } } : {};
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

// @desc    Update a course catalog entry
// @route   PUT /api/courses/:id
async function updateCourse(req, res) {
  try {
    const { course_code, title, department, credits } = req.body;

    // Find the course by ID and update it with the new fields
    // { new: true } returns the modified document instead of the original
    // { runValidators: true } ensures the new data still obeys your schema rules
    const updatedCourse = await Course.findByIdAndUpdate(
      req.params.id,
      { course_code, title, department, credits },
      { new: true, runValidators: true }
    );

    if (!updatedCourse) {
      return res.status(404).json({ message: 'Course not found' });
    }

    res.json(updatedCourse);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'A course with that course_code already exists' });
    }
    res.status(400).json({ message: 'Failed to update course', error: err.message });
  }
}

// @desc    Delete a course catalog entry
// @route   DELETE /api/courses/:id
async function deleteCourse(req, res) {
  try {
    const deletedCourse = await Course.findByIdAndDelete(req.params.id);

    if (!deletedCourse) {
      return res.status(404).json({ message: 'Course not found' });
    }

    res.json({ message: 'Course successfully deleted', deletedCourse });
  } catch (err) {
    res.status(400).json({ message: 'Failed to delete course', error: err.message });
  }
}

// Don't forget to export them!
module.exports = { 
  getCourses, 
  getCourseById, 
  createCourse, 
  updateCourse, 
  deleteCourse 
};