// controllers/courseController.js
const Course = require('../collections/Course');

// @desc    Get all courses
// @route   GET /api/courses
const getCourses = async (req, res) => {
    try {
        const courses = await Course.find({});
        res.status(200).json(courses);
    } catch (error) {
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

// @desc    Create a new course
// @route   POST /api/courses
const createCourse = async (req, res) => {
    try {
        const { title, code, instructor } = req.body;
        const newCourse = await Course.create({ title, code, instructor });
        res.status(201).json(newCourse);
    } catch (error) {
        res.status(400).json({ message: "Invalid data", error: error.message });
    }
};

module.exports = { getCourses, createCourse };