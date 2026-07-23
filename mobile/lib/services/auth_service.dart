import 'api_client.dart';
import 'auth_state.dart';

/// Mirrors frontend/src/api/auth.js — one function per backend/routes/auth-routes.js route.
class AuthService {
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
    });
    return res as Map<String, dynamic>;
  }

  /// On success, stores the session (token + user) in AuthState.
  static Future<void> verifyEmail({required String email, required String code}) async {
    final res = await ApiClient.post('/auth/verify-email', body: {'email': email, 'code': code});
    await _storeSession(res as Map<String, dynamic>);
  }

  static Future<void> resendVerification({required String email}) async {
    await ApiClient.post('/auth/resend-verification', body: {'email': email});
  }

  /// On success, stores the session (token + user) in AuthState.
  static Future<void> login({required String email, required String password}) async {
    final res = await ApiClient.post('/auth/login', body: {'email': email, 'password': password});
    await _storeSession(res as Map<String, dynamic>);
  }

  /// Returns the backend's confirmation message (always a generic "if
  /// registered" string, deliberately not confirming whether the email
  /// exists) so callers can display it directly, matching the web.
  static Future<String> forgotPassword({required String email}) async {
    final res = await ApiClient.post('/auth/forgot-password', body: {'email': email});
    return (res as Map<String, dynamic>)['message'] as String? ??
        'If that email is registered, a reset code has been sent.';
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/reset-password', body: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  static Future<void> logout() => AuthState.instance.logout();

  static Future<void> _storeSession(Map<String, dynamic> body) async {
    await AuthState.instance.setSession(
      token: body['token'] as String,
      userId: body['id'] as String,
      username: body['username'] as String,
      email: body['email'] as String,
    );
  }
}
