// routes/courseRoutes.js
const express = require('express');
const router = express.Router();
const { getCourses, createCourse } = require('../controllers/course-controller');

// Map endpoints to controller functions
router.route('/').get(getCourses).post(createCourse);

module.exports = router;