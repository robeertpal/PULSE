import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _isAuthenticatedKey = 'pulse_is_authenticated';
  static const String _userIdKey = 'pulse_user_id';
  static const String _sessionTokenKey = 'pulse_session_token';
  static const String _emailKey = 'pulse_user_email';
  static const String _userNameKey = 'pulse_user_name';

  Future<void> saveSession({
    required int userId,
    required String sessionToken,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_sessionTokenKey, sessionToken);
    await prefs.setString(_emailKey, email);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(_isAuthenticatedKey) ?? false;
    final sessionToken = prefs.getString(_sessionTokenKey);
    return isAuthenticated && sessionToken != null && sessionToken.isNotEmpty;
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userNameKey);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }
}
