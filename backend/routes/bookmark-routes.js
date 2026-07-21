const express = require('express');
const router = express.Router();
const { createBookmark, deleteBookmark, getMyBookmarks } = require('../controllers/bookmark-controller');

const protect = require('../middleware/authMiddleware');

router.get('/mine', protect, getMyBookmarks);
router.post('/', protect, createBookmark);
router.delete('/:reviewId', protect, deleteBookmark);

module.exports = router;
