import '../models/bookmark.dart';
import 'api_client.dart';

/// Mirrors backend/routes/bookmark-routes.js and frontend/src/api/
/// bookmarks.js.
class BookmarkService {
  static Future<List<Bookmark>> getMine() async {
    final res = await ApiClient.get('/bookmarks/mine');
    return (res as List)
        .map((e) => Bookmark.tryFromJson(e as Map<String, dynamic>))
        .whereType<Bookmark>()
        .toList();
  }

  /// Idempotent server-side (200 if it already exists, 201 if new) — the
  /// caller doesn't need to special-case either.
  static Future<void> create(String reviewId) async {
    await ApiClient.post('/bookmarks', body: {'reviewId': reviewId});
  }

  static Future<void> delete(String reviewId) async {
    await ApiClient.delete('/bookmarks/$reviewId');
  }
}
