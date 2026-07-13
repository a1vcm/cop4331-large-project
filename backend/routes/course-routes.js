// routes/courseRoutes.js
const express = require('express');
const router = express.Router();
const { getCourses, getCourseById, createCourse } = require('../controllers/course-controller');

// 1. GET /api/courses (Handles broad list fetching AND text searching)
router.get('/', getCourses);

// 2. GET /api/courses/:id (Fetches a single course by its MongoDB ObjectId)
router.get('/:id', getCourseById);

// 3. POST /api/courses (Creates a new course entry)
router.post('/', createCourse);

module.exports = router;