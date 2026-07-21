const express = require('express');
const router = express.Router();
const { getCourseResources, createResource, deleteResource } = require('../controllers/resource-controller');

const protect = require('../middleware/authMiddleware');

router.get('/course/:courseId', getCourseResources);
router.post('/', protect, createResource);
router.delete('/:id', protect, deleteResource);

module.exports = router;
