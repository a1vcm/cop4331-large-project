import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/review_service.dart';

http.Request _mock(Map<String, dynamic> jsonBody, {int status = 200, void Function(http.Request)? capture}) {
  ApiClient.client = MockClient.streaming((request, bodyStream) async {
    capture?.call(request as http.Request);
    return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(jsonBody))), status);
  });
  return http.Request('GET', Uri.parse('unused://'));
}

Map<String, dynamic> _reviewJson() => {
      '_id': 'r1',
      'courseId': 'c1',
      'userId': 'u1',
      'quality': 4.5,
      'difficulty': 3,
      'workload': 2,
      'gradingFairness': 4,
      'professorRating': 5,
      'attendance': 3,
      'grade': 'A',
      'comment': 'Great course',
      'tags': ['Easy A'],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => ApiClient.client = http.Client());

  test('createReview sends every rating dimension and tags', () async {
    http.Request? captured;
    _mock(_reviewJson(), status: 201, capture: (r) => captured = r);

    final review = await ReviewService.createReview(
      courseId: 'c1',
      instructor: 'Dr. Smith',
      term: 'Fall 2026',
      quality: 4.5,
      difficulty: 3,
      workload: 2,
      gradingFairness: 4,
      professorRating: 5,
      attendance: 3,
      grade: 'A',
      comment: 'Great course',
      tags: ['Easy A'],
    );

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['courseId'], 'c1');
    expect(body['quality'], 4.5);
    expect(body['difficulty'], 3);
    expect(body['workload'], 2);
    expect(body['gradingFairness'], 4);
    expect(body['professorRating'], 5);
    expect(body['attendance'], 3);
    expect(body['grade'], 'A');
    expect(body['tags'], ['Easy A']);
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/reviews');
    expect(review.quality, 4.5);
  });

  test('updateReview sends empty strings unconditionally, so a field can be cleared', () async {
    http.Request? captured;
    _mock(_reviewJson(), capture: (r) => captured = r);

    await ReviewService.updateReview(
      id: 'r1',
      // instructor/term/grade/comment deliberately left at their empty
      // defaults, mirroring "the user cleared this field on edit".
      quality: 4.5,
      difficulty: 3,
    );

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['instructor'], '');
    expect(body['term'], '');
    expect(body['grade'], '');
    expect(body['comment'], '');
    expect(captured!.method, 'PUT');
    expect(captured!.url.path, '/api/reviews/r1');
  });

  test('propagates ApiException on error responses', () async {
    ApiClient.client = MockClient((request) async {
      return http.Response(jsonEncode({'message': 'You have already reviewed this course'}), 409);
    });

    expect(
      () => ReviewService.createReview(courseId: 'c1', quality: 4, difficulty: 3),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'You have already reviewed this course')),
    );
  });
}
