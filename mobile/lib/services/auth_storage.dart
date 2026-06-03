import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _isAuthenticatedKey = 'pulse_is_authenticated';
  static const String _userIdKey = 'pulse_user_id';
  static const String _sessionTokenKey = 'pulse_session_token';
  static const String _emailKey = 'pulse_user_email';
  static const String _userNameKey = 'pulse_user_name';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveSession({
    required int userId,
    required String sessionToken,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setInt(_userIdKey, userId);
    await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);
    await prefs.remove(_sessionTokenKey);
    await prefs.setString(_emailKey, email);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(_isAuthenticatedKey) ?? false;
    final sessionToken = await getSessionToken();
    return isAuthenticated && sessionToken != null && sessionToken.isNotEmpty;
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    final secureToken = await _secureStorage.read(key: _sessionTokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    final legacyToken = prefs.getString(_sessionTokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _sessionTokenKey, value: legacyToken);
      await prefs.remove(_sessionTokenKey);
      return legacyToken;
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_sessionTokenKey);
    await _secureStorage.delete(key: _sessionTokenKey);
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
