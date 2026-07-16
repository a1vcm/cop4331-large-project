import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide auth session: current token + user info, persisted to disk so
/// login survives an app restart. Mirrors what frontend/src/api/client.js
/// does with localStorage, but as a notifiable singleton so screens can
/// react to login/logout (e.g. the home screen swapping "Log In" for
/// "Dashboard").
class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  static const _tokenKey = 'knightrate_token';
  static const _idKey = 'knightrate_user_id';
  static const _usernameKey = 'knightrate_username';
  static const _emailKey = 'knightrate_email';

  String? token;
  String? userId;
  String? username;
  String? email;

  bool get isLoggedIn => token != null;

  /// Must be awaited once at app startup before the first frame that reads
  /// auth state (see main.dart).
  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    userId = prefs.getString(_idKey);
    username = prefs.getString(_usernameKey);
    email = prefs.getString(_emailKey);
    notifyListeners();
  }

  Future<void> setSession({
    required String token,
    required String userId,
    required String username,
    required String email,
  }) async {
    this.token = token;
    this.userId = userId;
    this.username = username;
    this.email = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_idKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    userId = null;
    username = null;
    email = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_idKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    notifyListeners();
  }
}
