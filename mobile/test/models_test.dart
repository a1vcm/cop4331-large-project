import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/course.dart';
import 'package:mobile/models/review.dart';

void main() {
  group('Course.difficultyKey', () {
    test('is unrated when numRatings is 0', () {
      final course = Course.fromJson({
        '_id': '1',
        'course_code': 'COP4331',
        'title': 'Process of Software Development',
        'avgRating': 0,
        'avgDifficulty': 0,
        'numRatings': 0,
      });
      expect(course.difficultyKey, 'unrated');
    });

    test('buckets easy/medium/hard by avgDifficulty', () {
      Course withDifficulty(double d) => Course.fromJson({
            '_id': '1',
            'course_code': 'COP4331',
            'title': 'Test',
            'avgRating': 4,
            'avgDifficulty': d,
            'numRatings': 5,
          });

      expect(withDifficulty(1.5).difficultyKey, 'easy');
      expect(withDifficulty(3.0).difficultyKey, 'medium');
      expect(withDifficulty(4.5).difficultyKey, 'hard');
    });
  });

  group('Review.fromJson', () {
    test('parses plain ObjectId strings from create/update responses', () {
      final review = Review.fromJson({
        '_id': 'r1',
        'courseId': 'c1',
        'userId': 'u1',
        'quality': 4,
        'difficulty': 2,
      });

      expect(review.courseId, 'c1');
      expect(review.courseCode, isNull);
      expect(review.userId, 'u1');
      expect(review.authorUsername, isNull);
    });

    test('parses populated courseId/userId sub-objects from list endpoints', () {
      final review = Review.fromJson({
        '_id': 'r1',
        'courseId': {'_id': 'c1', 'course_code': 'COP4331', 'title': 'Software Dev'},
        'userId': {'_id': 'u1', 'username': 'ci-tester'},
        'quality': 4,
        'difficulty': 2,
      });

      expect(review.courseId, 'c1');
      expect(review.courseCode, 'COP4331');
      expect(review.userId, 'u1');
      expect(review.authorUsername, 'ci-tester');
    });
  });
}
