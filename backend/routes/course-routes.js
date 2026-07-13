const express = require('express');
const router = express.Router();
const { getCourses, getCourseById, createCourse } = require('../controllers/course-controller');

router.route('/').get(getCourses).post(createCourse);
router.route('/:id').get(getCourseById);

module.exports = router;
