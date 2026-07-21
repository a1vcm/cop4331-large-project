import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_state.dart';

/// Base URL for the backend API. Defaults to the deployed production API so
/// the app works out of the box on a real device. Override for local dev with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:5001/api
/// (use your Mac's LAN IP instead of localhost when running on a physical
/// device or the iOS Simulator can't reach it — the simulator shares your
/// Mac's network stack, but a physical iPhone can't resolve "localhost" as
/// your dev machine).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://cop4331-summer2026-17.xyz/api',
);

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Thin wrapper around `http`, mirroring frontend/src/api/client.js:
/// attaches the stored bearer token to every request and normalizes error
/// messages from the backend's `{ message: "..." }` error shape.
class ApiClient {
  /// Overridable in tests (e.g. `ApiClient.client = MockClient(...)`); real
  /// requests use a plain http.Client otherwise.
  static http.Client client = http.Client();

  static Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return _send('PUT', path, body: body);
  }

  /// [body] mirrors axios's `api.delete(url, { data })` — DELETE /users/me
  /// needs to send { password }, which a bodyless delete can't express.
  static Future<dynamic> delete(String path, {Map<String, dynamic>? body}) {
    return _send('DELETE', path, body: body);
  }

  static Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthState.instance.token;
    if (token != null) headers['Authorization'] = 'Bearer $token';

    late http.Response res;
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await client.send(request).timeout(const Duration(seconds: 15));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.', 0);
    }

    // A non-JSON body (e.g. Express's plain-text 404 page for a route that
    // isn't deployed, or an nginx/proxy error page) must not let a raw
    // FormatException escape here — every caller only catches ApiException.
    dynamic decoded;
    try {
      decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      decoded = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded == null && res.body.isNotEmpty) {
        throw ApiException('Unexpected response from the server.', res.statusCode);
      }
      return decoded;
    }

    final message = (decoded is Map && decoded['message'] is String)
        ? decoded['message'] as String
        : 'Something went wrong. Please try again.';
    throw ApiException(message, res.statusCode);
  }
}
