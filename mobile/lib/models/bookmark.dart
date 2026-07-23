import 'review.dart';

/// Mirrors GET /bookmarks/mine's populate shape (backend/controllers/
/// bookmark-controller.js:getMyBookmarks) — reviewId populated with its
/// nested courseId/userId, so the bookmarks screen can render full review
/// cards without extra round-trips.
class Bookmark {
  final String id;
  final Review review;

  Bookmark({required this.id, required this.review});

  /// Returns null when reviewId isn't a populated object (a deleted review,
  /// or an older backend that hasn't picked up the populate change yet) —
  /// mirrors BookmarksPage.jsx's defensive skip rather than throwing.
  static Bookmark? tryFromJson(Map<String, dynamic> json) {
    final reviewId = json['_id'];
    final rawReview = json['reviewId'];
    if (reviewId is! String || rawReview is! Map) return null;
    return Bookmark(id: reviewId, review: Review.fromJson(rawReview.cast<String, dynamic>()));
  }
}
