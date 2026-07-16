import '../models/review.dart';
import 'api_client.dart';

/// Wraps backend/routes/review-routes.js. No frontend/src/api equivalent
/// exists yet — the web app hasn't built review UI either.
class ReviewService {
  static Future<List<Review>> getCourseReviews(String courseId) async {
    final res = await ApiClient.get('/reviews/course/$courseId');
    return (res as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Review>> getMyReviews() async {
    final res = await ApiClient.get('/reviews/mine');
    return (res as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Review> createReview({
    required String courseId,
    String? instructor,
    String? term,
    required int quality,
    required int difficulty,
    String? grade,
    String? comment,
  }) async {
    final res = await ApiClient.post('/reviews', body: {
      'courseId': courseId,
      if (instructor != null && instructor.isNotEmpty) 'instructor': instructor,
      if (term != null && term.isNotEmpty) 'term': term,
      'quality': quality,
      'difficulty': difficulty,
      if (grade != null && grade.isNotEmpty) 'grade': grade,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return Review.fromJson(res as Map<String, dynamic>);
  }

  static Future<Review> updateReview({
    required String id,
    String? instructor,
    String? term,
    required int quality,
    required int difficulty,
    String? grade,
    String? comment,
  }) async {
    final res = await ApiClient.put('/reviews/$id', body: {
      'instructor': instructor,
      'term': term,
      'quality': quality,
      'difficulty': difficulty,
      'grade': grade,
      'comment': comment,
    });
    return Review.fromJson(res as Map<String, dynamic>);
  }

  static Future<void> deleteReview(String id) async {
    await ApiClient.delete('/reviews/$id');
  }
}
