// controllers/reviewController.js
const mongoose = require('mongoose');
const Review = require('../collections/Review');
const Course = require('../collections/Course');
const Bookmark = require('../collections/Bookmark');

// Helper function to recalculate and update course statistics
async function updateCourseStats(courseId) {
  try {
    // Aggregation pipelines don't auto-cast query values the way find()
    // does, so this needs an explicit ObjectId or the $match silently
    // matches nothing and every course's stats get reset to 0.
    const courseObjectId = new mongoose.Types.ObjectId(courseId);
    const stats = await Review.aggregate([
      // 1. Find all reviews matching this courseId
      { $match: { courseId: courseObjectId } },
      // 2. Calculate totals and averages using your schema's "quality" field
      {
        $group: {
          _id: '$courseId',
          numRatings: { $sum: 1 },
          avgRating: { $avg: '$quality' }, // Matches your "quality" field
          avgDifficulty: { $avg: '$difficulty' },
        },
      },
    ]);

    if (stats.length > 0) {
      await Course.findByIdAndUpdate(courseId, {
        numRatings: stats[0].numRatings,
        avgRating: Math.round(stats[0].avgRating * 10) / 10, // Rounds to 1 decimal place
        avgDifficulty: Math.round(stats[0].avgDifficulty * 10) / 10,
        lastReviewedAt: new Date(),
      });
    } else {
      // Reset defaults if the last remaining review is deleted
      await Course.findByIdAndUpdate(courseId, {
        numRatings: 0,
        avgRating: 0,
        avgDifficulty: 0,
        lastReviewedAt: null,
      });
    }
  } catch (err) {
    console.error(`[stats-aggregation] Error updating course ${courseId}:`, err.message);
  }
}

// @desc    Create a new review
// @route   POST /api/reviews
async function createReview(req, res) {
  try {
    // Destructuring to match your exact schema layout
    const {
      courseId, instructor, term, quality, difficulty, workload, gradingFairness,
      professorRating, attendance, grade, comment, tags,
    } = req.body;
    const userId = req.user.id; // Populated by your JWT auth middleware

    if (!courseId || !quality || !difficulty) {
      return res.status(400).json({ message: 'courseId, quality, and difficulty are required' });
    }

    // Double-check that the course exists in Atlas
    const courseExists = await Course.findById(courseId);
    if (!courseExists) {
      return res.status(404).json({ message: 'Course not found' });
    }

    // Check if this user has already reviewed this specific course
    const existingReview = await Review.findOne({ courseId, userId });
    if (existingReview) {
      return res.status(409).json({ message: 'You have already reviewed this course' });
    }

    // Create the review matching your exact schema layout
    const review = await Review.create({
      courseId,
      userId,
      instructor,
      term,
      quality,
      difficulty,
      workload,
      gradingFairness,
      professorRating,
      attendance,
      grade,
      comment,
      tags,
    });

    // Recalculate average stats for the course
    await updateCourseStats(courseId);

    res.status(201).json(review);
  } catch (err) {
    res.status(400).json({ message: 'Failed to submit review', error: err.message });
  }
}

// @desc    Get all reviews for a specific course
// @route   GET /api/reviews/course/:courseId
async function getCourseReviews(req, res) {
  try {
    const reviews = await Review.find({ courseId: req.params.courseId })
      .populate('userId', 'username') // Populates the creator's username safely
      .sort({ createdAt: -1 });

    res.json(reviews);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch reviews', error: err.message });
  }
}

// @desc    Get the logged-in user's own reviews
// @route   GET /api/reviews/mine
async function getMyReviews(req, res) {
  try {
    const reviews = await Review.find({ userId: req.user.id })
      .populate('courseId', 'course_code title department')
      .sort({ createdAt: -1 });

    res.json(reviews);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch your reviews', error: err.message });
  }
}

// @desc    Update an existing review
// @route   PUT /api/reviews/:id
async function updateReview(req, res) {
  try {
    const {
      instructor, term, quality, difficulty, workload, gradingFairness,
      professorRating, attendance, grade, comment, tags,
    } = req.body;
    const userId = req.user.id;

    const review = await Review.findById(req.params.id);
    if (!review) {
      return res.status(404).json({ message: 'Review not found' });
    }

    // Security check: Only let the original author update their review
    if (review.userId.toString() !== userId) {
      return res.status(403).json({ message: 'Not authorized to edit this review' });
    }

    // Update with incoming values, fallback to current values if fields are omitted
    review.instructor = instructor !== undefined ? instructor : review.instructor;
    review.term = term !== undefined ? term : review.term;
    review.quality = quality !== undefined ? quality : review.quality;
    review.difficulty = difficulty !== undefined ? difficulty : review.difficulty;
    review.workload = workload !== undefined ? workload : review.workload;
    review.gradingFairness = gradingFairness !== undefined ? gradingFairness : review.gradingFairness;
    review.professorRating = professorRating !== undefined ? professorRating : review.professorRating;
    review.attendance = attendance !== undefined ? attendance : review.attendance;
    review.grade = grade !== undefined ? grade : review.grade;
    review.comment = comment !== undefined ? comment : review.comment;
    review.tags = tags !== undefined ? tags : review.tags;

    await review.save();
    await updateCourseStats(review.courseId);

    res.json(review);
  } catch (err) {
    res.status(400).json({ message: 'Failed to update review', error: err.message });
  }
}

// @desc    Delete a review
// @route   DELETE /api/reviews/:id
async function deleteReview(req, res) {
  try {
    const userId = req.user.id;
    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({ message: 'Review not found' });
    }

    // Security check: Only let the author delete it
    if (review.userId.toString() !== userId) {
      return res.status(403).json({ message: 'Not authorized to delete this review' });
    }

    await review.deleteOne();
    await Bookmark.deleteMany({ reviewId: review._id });
    await updateCourseStats(review.courseId);

    res.json({ message: 'Review deleted successfully' });
  } catch (err) {
    res.status(400).json({ message: 'Failed to delete review', error: err.message });
  }
}

module.exports = {
  createReview,
  getCourseReviews,
  getMyReviews,
  updateReview,
  deleteReview,
};