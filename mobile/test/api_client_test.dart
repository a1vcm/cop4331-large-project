import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';

void main() {
  tearDown(() => ApiClient.client = http.Client());

  test('delete sends a JSON body when one is provided', () async {
    http.Request? captured;
    ApiClient.client = MockClient.streaming((request, bodyStream) async {
      captured = request as http.Request;
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'message': 'Account deleted'}))),
        200,
      );
    });

    final result = await ApiClient.delete('/users/me', body: {'password': 'hunter2'});

    expect(captured!.method, 'DELETE');
    expect(jsonDecode(captured!.body), {'password': 'hunter2'});
    expect(result, {'message': 'Account deleted'});
  });

  test('delete with no body sends an empty request body', () async {
    http.Request? captured;
    ApiClient.client = MockClient.streaming((request, bodyStream) async {
      captured = request as http.Request;
      return http.StreamedResponse(const Stream.empty(), 200);
    });

    await ApiClient.delete('/reviews/abc');

    expect(captured!.body, '');
  });
}
