import 'api_client.dart';
import 'auth_state.dart';

/// Account-management endpoints (backend: routes/users-routes.js).
/// Mirrors frontend/src/api/users.js, one function per route.
class UserService {
  static Future<void> changeUsername(String username) async {
    final res = await ApiClient.put('/users/username', body: {'username': username}) as Map<String, dynamic>;
    await _updateSession(username: res['username'] as String);
  }

  static Future<String> requestEmailChange(String newEmail) async {
    final res = await ApiClient.post('/users/email/request', body: {'newEmail': newEmail}) as Map<String, dynamic>;
    return res['message'] as String;
  }

  static Future<void> verifyEmailChange(String code) async {
    final res = await ApiClient.post('/users/email/verify', body: {'code': code}) as Map<String, dynamic>;
    await _updateSession(email: res['email'] as String);
  }

  static Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await ApiClient.put('/users/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }) as Map<String, dynamic>;
    return res['message'] as String;
  }

  static Future<void> deleteAccount(String password) async {
    await ApiClient.delete('/users/me', body: {'password': password});
    await AuthState.instance.logout();
  }

  /// Persists a changed username/email, keeping the rest of the session as-is.
  static Future<void> _updateSession({String? username, String? email}) {
    final auth = AuthState.instance;
    return auth.setSession(
      token: auth.token!,
      userId: auth.userId!,
      username: username ?? auth.username!,
      email: email ?? auth.email!,
    );
  }
}
