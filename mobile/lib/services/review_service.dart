import '../models/review.dart';
import 'api_client.dart';

/// Mirrors backend/routes/review-routes.js and frontend/src/api/reviews.js.
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
    String instructor = '',
    String term = '',
    required double quality,
    required int difficulty,
    int workload = 3,
    int gradingFairness = 3,
    int professorRating = 3,
    int attendance = 3,
    String grade = '',
    String comment = '',
    List<String> tags = const [],
  }) async {
    final res = await ApiClient.post('/reviews', body: {
      'courseId': courseId,
      'instructor': instructor,
      'term': term,
      'quality': quality,
      'difficulty': difficulty,
      'workload': workload,
      'gradingFairness': gradingFairness,
      'professorRating': professorRating,
      'attendance': attendance,
      'grade': grade,
      'comment': comment,
      'tags': tags,
    });
    return Review.fromJson(res as Map<String, dynamic>);
  }

  /// All fields are sent unconditionally (matching frontend/src/pages/
  /// WriteReviewPage.jsx). The controller does
  /// `review.field = field !== undefined ? field : review.field`, so a
  /// deliberately-empty string (e.g. clearing the instructor) must be sent
  /// as `''`, not omitted — omitting it would leave the old value in place
  /// and make a field impossible to clear once set.
  static Future<Review> updateReview({
    required String id,
    String instructor = '',
    String term = '',
    required double quality,
    required int difficulty,
    int workload = 3,
    int gradingFairness = 3,
    int professorRating = 3,
    int attendance = 3,
    String grade = '',
    String comment = '',
    List<String> tags = const [],
  }) async {
    final res = await ApiClient.put('/reviews/$id', body: {
      'instructor': instructor,
      'term': term,
      'quality': quality,
      'difficulty': difficulty,
      'workload': workload,
      'gradingFairness': gradingFairness,
      'professorRating': professorRating,
      'attendance': attendance,
      'grade': grade,
      'comment': comment,
      'tags': tags,
    });
    return Review.fromJson(res as Map<String, dynamic>);
  }

  static Future<void> deleteReview(String id) async {
    await ApiClient.delete('/reviews/$id');
  }
}
