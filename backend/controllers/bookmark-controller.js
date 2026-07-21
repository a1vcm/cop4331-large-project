const Bookmark = require('../collections/Bookmark');

// POST /api/bookmarks  body: { reviewId }
async function createBookmark(req, res) {
  try {
    const { reviewId } = req.body;
    if (!reviewId) {
      return res.status(400).json({ message: 'reviewId is required' });
    }

    // Idempotent: if it already exists, just return it rather than erroring.
    const existing = await Bookmark.findOne({ userId: req.user._id, reviewId });
    if (existing) {
      return res.status(200).json(existing);
    }

    const bookmark = await Bookmark.create({ userId: req.user._id, reviewId });
    res.status(201).json(bookmark);
  } catch (err) {
    if (err.code === 11000) {
      const existing = await Bookmark.findOne({ userId: req.user._id, reviewId: req.body.reviewId });
      return res.status(200).json(existing);
    }
    res.status(400).json({ message: 'Failed to create bookmark', error: err.message });
  }
}

// DELETE /api/bookmarks/:reviewId
async function deleteBookmark(req, res) {
  try {
    await Bookmark.findOneAndDelete({ userId: req.user._id, reviewId: req.params.reviewId });
    res.json({ message: 'Bookmark removed' });
  } catch (err) {
    res.status(400).json({ message: 'Failed to remove bookmark', error: err.message });
  }
}

// GET /api/bookmarks/mine — returns just the reviewIds the user has bookmarked.
async function getMyBookmarks(req, res) {
  try {
    const bookmarks = await Bookmark.find({ userId: req.user._id }).select('reviewId');
    res.json(bookmarks.map((b) => b.reviewId));
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch bookmarks', error: err.message });
  }
}

module.exports = { createBookmark, deleteBookmark, getMyBookmarks };
