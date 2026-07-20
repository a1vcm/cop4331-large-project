import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/auth_state.dart';
import 'package:mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Request _mock(Map<String, dynamic> jsonBody, {int status = 200, void Function(http.Request)? capture}) {
  ApiClient.client = MockClient.streaming((request, bodyStream) async {
    capture?.call(request as http.Request);
    return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(jsonBody))), status);
  });
  return http.Request('GET', Uri.parse('unused://'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthState.instance.setSession(
      token: 'tok-1',
      userId: 'u1',
      username: 'oldname',
      email: 'old@ucf.edu',
    );
  });

  tearDown(() => ApiClient.client = http.Client());

  test('changeUsername sends { username } and updates AuthState', () async {
    http.Request? captured;
    _mock({'message': 'Username updated', 'username': 'newname'}, capture: (r) => captured = r);

    await UserService.changeUsername('newname');

    expect(jsonDecode(captured!.body), {'username': 'newname'});
    expect(captured!.method, 'PUT');
    expect(captured!.url.path, '/api/users/username');
    expect(AuthState.instance.username, 'newname');
    expect(AuthState.instance.token, 'tok-1', reason: 'unrelated session fields must survive');
  });

  test('requestEmailChange sends { newEmail } and returns the message', () async {
    http.Request? captured;
    _mock({'message': 'Verification code sent to the new email address'}, capture: (r) => captured = r);

    final message = await UserService.requestEmailChange('new@ucf.edu');

    expect(jsonDecode(captured!.body), {'newEmail': 'new@ucf.edu'});
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/users/email/request');
    expect(message, 'Verification code sent to the new email address');
  });

  test('verifyEmailChange sends { code } and updates AuthState.email', () async {
    http.Request? captured;
    _mock({'message': 'Email updated', 'email': 'new@ucf.edu'}, capture: (r) => captured = r);

    await UserService.verifyEmailChange('123456');

    expect(jsonDecode(captured!.body), {'code': '123456'});
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/users/email/verify');
    expect(AuthState.instance.email, 'new@ucf.edu');
  });

  test('changePassword sends currentPassword/newPassword and returns the message', () async {
    http.Request? captured;
    _mock({'message': 'Password changed'}, capture: (r) => captured = r);

    final message = await UserService.changePassword(
      currentPassword: 'old-pw',
      newPassword: 'new-pw',
    );

    expect(jsonDecode(captured!.body), {'currentPassword': 'old-pw', 'newPassword': 'new-pw'});
    expect(captured!.method, 'PUT');
    expect(captured!.url.path, '/api/users/password');
    expect(message, 'Password changed');
  });

  test('deleteAccount sends { password } and logs out', () async {
    http.Request? captured;
    _mock({'message': 'Account deleted'}, capture: (r) => captured = r);

    await UserService.deleteAccount('my-pw');

    expect(jsonDecode(captured!.body), {'password': 'my-pw'});
    expect(captured!.method, 'DELETE');
    expect(captured!.url.path, '/api/users/me');
    expect(AuthState.instance.isLoggedIn, false);
  });

  test('propagates ApiException on error responses', () async {
    ApiClient.client = MockClient((request) async {
      return http.Response(jsonEncode({'message': 'Current password is incorrect'}), 401);
    });

    expect(
      () => UserService.changePassword(currentPassword: 'wrong', newPassword: 'new-pw'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Current password is incorrect')),
    );
  });
}
