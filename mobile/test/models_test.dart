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

    test('quality parses as a double, preserving half-star increments', () {
      final review = Review.fromJson({
        '_id': 'r1',
        'courseId': 'c1',
        'userId': 'u1',
        'quality': 4.5,
        'difficulty': 2,
      });

      expect(review.quality, 4.5);
      expect(review.quality, isA<double>());
    });

    test('parses workload/gradingFairness/professorRating/attendance/tags/voteScore', () {
      final review = Review.fromJson({
        '_id': 'r1',
        'courseId': 'c1',
        'userId': 'u1',
        'quality': 4,
        'difficulty': 2,
        'workload': 3,
        'gradingFairness': 5,
        'professorRating': 4,
        'attendance': 2,
        'tags': ['Easy A', 'Amazing Lectures'],
        'voteScore': {'helpful': 7, 'notHelpful': 1},
      });

      expect(review.workload, 3);
      expect(review.gradingFairness, 5);
      expect(review.professorRating, 4);
      expect(review.attendance, 2);
      expect(review.tags, ['Easy A', 'Amazing Lectures']);
      expect(review.voteHelpful, 7);
      expect(review.voteNotHelpful, 1);
    });

    test('optional rating dimensions default to null/empty when absent', () {
      final review = Review.fromJson({
        '_id': 'r1',
        'courseId': 'c1',
        'userId': 'u1',
        'quality': 4,
        'difficulty': 2,
      });

      expect(review.workload, isNull);
      expect(review.gradingFairness, isNull);
      expect(review.professorRating, isNull);
      expect(review.attendance, isNull);
      expect(review.tags, isEmpty);
      expect(review.voteHelpful, 0);
      expect(review.voteNotHelpful, 0);
    });
  });
}
