import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/resource_service.dart';

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

  test('getForCourse parses populated userId', () async {
    _mock([
      {
        '_id': 'res1',
        'courseId': 'c1',
        'userId': {'_id': 'u1', 'username': 'ci-tester'},
        'title': 'Course syllabus',
        'url': 'https://example.com/syllabus',
      },
    ]);

    final resources = await ResourceService.getForCourse('c1');

    expect(resources.length, 1);
    expect(resources.first.title, 'Course syllabus');
    expect(resources.first.authorUsername, 'ci-tester');
  });

  test('create sends { courseId, title, url } to POST /resources', () async {
    http.Request? captured;
    _mock({
      '_id': 'res1',
      'courseId': 'c1',
      'userId': {'_id': 'u1', 'username': 'ci-tester'},
      'title': 'Course syllabus',
      'url': 'https://example.com/syllabus',
    }, status: 201, capture: (r) => captured = r);

    await ResourceService.create(courseId: 'c1', title: 'Course syllabus', url: 'https://example.com/syllabus');

    expect(
      jsonDecode(captured!.body),
      {'courseId': 'c1', 'title': 'Course syllabus', 'url': 'https://example.com/syllabus'},
    );
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/resources');
  });

  test('delete calls DELETE /resources/:id', () async {
    http.Request? captured;
    _mock({'message': 'Resource deleted'}, capture: (r) => captured = r);

    await ResourceService.delete('res1');

    expect(captured!.method, 'DELETE');
    expect(captured!.url.path, '/api/resources/res1');
  });

  test('propagates ApiException on error responses', () async {
    ApiClient.client = MockClient((request) async {
      return http.Response(jsonEncode({'message': 'Not authorized to delete this resource'}), 403);
    });

    expect(
      () => ResourceService.delete('res1'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Not authorized to delete this resource')),
    );
  });
}
