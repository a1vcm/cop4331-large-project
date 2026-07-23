import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/bookmark_service.dart';

http.Request _mock(dynamic jsonBody, {int status = 200, void Function(http.Request)? capture}) {
  ApiClient.client = MockClient.streaming((request, bodyStream) async {
    capture?.call(request as http.Request);
    return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(jsonBody))), status);
  });
  return http.Request('GET', Uri.parse('unused://'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => ApiClient.client = http.Client());

  test('getMine parses populated bookmarks and skips unpopulated ones', () async {
    _mock([
      {
        '_id': 'b1',
        'reviewId': {
          '_id': 'r1',
          'courseId': {'_id': 'c1', 'course_code': 'COP4331', 'title': 'Software Dev'},
          'userId': {'_id': 'u1', 'username': 'ci-tester'},
          'quality': 4.5,
          'difficulty': 3,
        },
      },
      // A stale/older-backend shape where reviewId never got populated —
      // must be skipped rather than throwing.
      {'_id': 'b2', 'reviewId': 'r2'},
    ]);

    final bookmarks = await BookmarkService.getMine();

    expect(bookmarks.length, 1);
    expect(bookmarks.first.id, 'b1', reason: 'Bookmark.id is the bookmark document\'s own _id');
    expect(bookmarks.first.review.id, 'r1', reason: 'the nested review keeps its own id, used for the delete call');
    expect(bookmarks.first.review.courseCode, 'COP4331');
  });

  test('create sends { reviewId } to POST /bookmarks', () async {
    http.Request? captured;
    _mock({'_id': 'b1', 'reviewId': 'r1', 'userId': 'u1'}, status: 201, capture: (r) => captured = r);

    await BookmarkService.create('r1');

    expect(jsonDecode(captured!.body), {'reviewId': 'r1'});
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/bookmarks');
  });

  test('delete calls DELETE /bookmarks/:reviewId', () async {
    http.Request? captured;
    _mock({'message': 'Bookmark removed'}, capture: (r) => captured = r);

    await BookmarkService.delete('r1');

    expect(captured!.method, 'DELETE');
    expect(captured!.url.path, '/api/bookmarks/r1');
  });

  test('propagates ApiException on error responses', () async {
    ApiClient.client = MockClient((request) async {
      return http.Response(jsonEncode({'message': 'reviewId is required'}), 400);
    });

    expect(
      () => BookmarkService.create(''),
      throwsA(isA<ApiException>()),
    );
  });
}
