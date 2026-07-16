// routes/review-routes.js
const express = require('express');
const router = express.Router();
const { 
  createReview, 
  getCourseReviews, 
  updateReview, 
  deleteReview 
} = require('../controllers/review-controller');

// Standard middleware verifying JWTs and attaching user info to req.user
const protect = require('../middleware/authMiddleware');


// Public route to see reviews
router.get('/course/:courseId', getCourseReviews);

// Protected routes (require valid JWT)
router.post('/', protect, createReview);
router.put('/:id', protect, updateReview);
router.delete('/:id', protect, deleteReview);

module.exports = router;