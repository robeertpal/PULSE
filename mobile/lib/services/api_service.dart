import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ad_item.dart';
import '../models/content_item.dart';
import '../models/filter_option.dart';
import '../models/publication_issue.dart';
import 'auth_storage.dart';

class ApiService {
  // Pentru local development:
  // - Web: http://localhost:8000
  // - iOS Simulator: http://127.0.0.1:8000
  // - Android Emulator: http://10.0.2.2:8000
  static const String _configuredBaseUrl = String.fromEnvironment(
    'PULSE_API_BASE_URL',
  );
  static String get baseUrl => _baseUrl;

  final AuthStorage _authStorage = AuthStorage();

  Future<Map<String, String>> _buildAuthHeaders() async {
    final sessionToken = await _authStorage.getSessionToken();
    if (sessionToken == null || sessionToken.isEmpty) {
      throw Exception('No active session token');
    }
    return {'Authorization': 'Bearer $sessionToken'};
  }

  static String get _baseUrl {
    final configured = _configuredBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }

    if (kDebugMode) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000';
      }
      if (kIsWeb) {
        return 'http://localhost:8000';
      }
      return 'http://127.0.0.1:8000';
    }

    return 'https://pulse-backend-5f9b.onrender.com';
  }

  String _buildRepeatedQueryString(Map<String, List<String>> queryParams) {
    final parts = <String>[];

    queryParams.forEach((key, values) {
      for (final value in values) {
        parts.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    });

    return parts.join('&');
  }

  String _trimmedResponseBody(String body) {
    const maxBodyLength = 1200;
    if (body.length <= maxBodyLength) return body;
    return '${body.substring(0, maxBodyLength)}...';
  }

  String _requestDiagnostics({
    required String url,
    required int statusCode,
    required String body,
  }) {
    final trimmedBody = _trimmedResponseBody(body);
    return 'URL apelat: $url\nStatus code: $statusCode\nBody backend: ${trimmedBody.isEmpty ? '(gol)' : trimmedBody}';
  }

  String _responseErrorMessage(http.Response response, String fallback) {
    final url = response.request?.url.toString() ?? baseUrl;
    var message = fallback;
    debugPrint(
      'Backend error: ${_requestDiagnostics(url: url, statusCode: response.statusCode, body: response.body)}',
    );
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) message = detail;
        final backendMessage = decoded['message'];
        if (backendMessage is String && backendMessage.isNotEmpty) {
          message = backendMessage;
        }
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) message = error;
      }
    } catch (_) {
      // Keep the caller's friendly fallback when the backend body is not JSON.
    }
    if (response.statusCode == 503) {
      return 'Emailul nu a putut fi trimis momentan. Te rugăm să încerci din nou.';
    }
    return message;
  }

  Exception _friendlyNetworkException(
    Object error,
    String actionLabel, {
    String? url,
  }) {
    final requestUrl = url ?? baseUrl;
    debugPrint(
      'Network error for $actionLabel: url=$requestUrl type=${error.runtimeType} details=$error',
    );
    if (error is TimeoutException) {
      return Exception(
        'Conexiunea durează prea mult. Te rugăm să încerci din nou.',
      );
    }
    if (error is http.ClientException) {
      return Exception(
        'Nu ne putem conecta momentan. Te rugăm să încerci din nou.',
      );
    }
    return Exception('A apărut o eroare. Te rugăm să încerci din nou.');
  }

  Future<void> _handleAuthFailure(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      await _authStorage.clearSession();
      throw Exception(
        'Sesiunea a expirat. Te rugăm să te autentifici din nou.',
      );
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    late final http.Response response;
    final url = '$baseUrl/api/login';
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'autentificarea', url: url);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseErrorMessage(response, 'Autentificare eșuată'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de autentificare neașteptat.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    late final http.Response response;
    final url = '$baseUrl/api/register';
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 35));
    } catch (error) {
      debugPrint('Register network error: url=$url error=$error');
      throw _friendlyNetworkException(
        error,
        'înregistrarea contului',
        url: url,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'Register backend error: ${_requestDiagnostics(url: url, statusCode: response.statusCode, body: response.body)}',
      );
      throw Exception(_responseErrorMessage(response, 'Înregistrare eșuată'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de înregistrare neașteptat.');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> getInterests() async {
    final url = '$baseUrl/interests';
    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(
        error,
        'încărcarea intereselor',
        url: url,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _responseErrorMessage(response, 'Nu am putut încărca interesele.'),
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Răspuns interese neașteptat.');
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> updateMyInterests({
    required List<int> interestIds,
  }) async {
    final url = '$baseUrl/api/me/interests';
    final headers = await _buildAuthHeaders();
    late final http.Response response;
    try {
      response = await http
          .put(
            Uri.parse(url),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'interest_ids': interestIds}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'salvarea intereselor', url: url);
    }

    await _handleAuthFailure(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _responseErrorMessage(response, 'Nu am putut salva interesele.'),
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns actualizare interese neașteptat.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otpCode,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/email-verifications/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp_code': otpCode}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'verificarea codului');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseErrorMessage(response, 'Verificare eșuată'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de verificare neașteptat.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> resendEmailOtp({required String email}) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/email-verifications/resend'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'retrimiterea codului');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseErrorMessage(response, 'Retrimitere eșuată'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de retrimitere neașteptat.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/password-resets/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'trimiterea codului');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _responseErrorMessage(response, 'Nu am putut trimite codul.'),
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de resetare neașteptat.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String otpCode,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/password-resets/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp_code': otpCode}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'verificarea codului');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseErrorMessage(response, 'Verificare eșuată'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de verificare neașteptat.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String otpCode,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/password-resets/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp_code': otpCode,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'resetarea parolei');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseErrorMessage(response, 'Resetare eșuată'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Răspuns de resetare neașteptat.');
    }
    return decoded;
  }

  Future<void> logout() async {
    final sessionToken = await _authStorage.getSessionToken();
    if (sessionToken == null || sessionToken.isEmpty) {
      return;
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_token': sessionToken}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception(_responseErrorMessage(response, 'Logout eșuat'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/me/change-password'),
            headers: headers,
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          _responseErrorMessage(response, 'Schimbarea parolei a esuat'),
        );
      }
    } catch (error) {
      throw _friendlyNetworkException(error, 'schimbarea parolei');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/me/profile'), headers: headers)
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut încărca profilul.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Răspuns profil neașteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(
    Map<String, dynamic> changes,
  ) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/me/profile'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode(changes),
          )
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut salva profilul.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns actualizare profil neasteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadMyProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/me/profile/avatar'),
      );
      request.headers.addAll(headers);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Nu am putut incarca poza de profil.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns upload avatar neasteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error uploading profile avatar: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyEmcActivity() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/me/emc-activity'), headers: headers)
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Nu am putut incarca activitatea EMC.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Raspuns activitate EMC neasteptat.');
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetching EMC activity: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyPayments() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/me/payments'), headers: headers)
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut incarca tranzactiile.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Raspuns tranzactii neasteptat.');
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyPaymentMethods() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/me/payment-methods'), headers: headers)
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Nu am putut incarca metodele de plata.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Raspuns metode de plata neasteptat.');
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addMyPaymentMethod({
    required String cardBrand,
    required String cardLast4,
    required int expMonth,
    required int expYear,
    bool isDefault = false,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/me/payment-methods'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'card_brand': cardBrand,
              'card_last4': cardLast4,
              'exp_month': expMonth,
              'exp_year': expYear,
              'is_default': isDefault,
            }),
          )
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut salva cardul.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns adaugare card neasteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error adding payment method: $e');
      rethrow;
    }
  }

  Future<void> deleteMyPaymentMethod(int id) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/me/payment-methods/$id'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut sterge cardul.'),
        );
      }
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setDefaultMyPaymentMethod(int id) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/me/payment-methods/$id/default'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut seta cardul implicit.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns card implicit neasteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/notifications'), headers: headers)
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut încărca notificările.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Răspuns notificări neașteptat.');
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/notifications/unread-count'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Nu am putut încărca numărul notificărilor.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Răspuns notificări neașteptat.');
      }
      final value = decoded['unread_count'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread notification count: $e');
      return 0;
    }
  }

  Future<void> markNotificationRead(int userNotificationId) async {
    final headers = await _buildAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$baseUrl/notifications/$userNotificationId/read'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));

    await _handleAuthFailure(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _responseErrorMessage(
          response,
          'Nu am putut marca notificarea citită.',
        ),
      );
    }
  }

  Future<void> markAllNotificationsRead() async {
    final headers = await _buildAuthHeaders();
    final response = await http
        .patch(Uri.parse('$baseUrl/notifications/read-all'), headers: headers)
        .timeout(const Duration(seconds: 10));

    await _handleAuthFailure(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _responseErrorMessage(
          response,
          'Nu am putut marca notificările citite.',
        ),
      );
    }
  }

  Future<List<ContentItem>> _getContentList(
    String path, {
    int limit = 10,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    try {
      final queryParams = <String, List<String>>{
        'limit': [limit.toString()],
      };
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category_ids'] = categoryIds
            .map((id) => id.toString())
            .toList();
      }
      if (specializationIds != null && specializationIds.isNotEmpty) {
        queryParams['specialization_ids'] = specializationIds
            .map((id) => id.toString())
            .toList();
      }

      final uri = Uri.parse(
        '$_baseUrl/$path',
      ).replace(query: _buildRepeatedQueryString(queryParams));
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load $path: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        throw Exception(decoded['error']);
      }
      if (decoded is! List) {
        throw Exception('Unexpected $path response format');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => ContentItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching $path: $e');
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  Future<List<ContentItem>> getArticles({
    int limit = 10,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    return _getContentList(
      'articles',
      limit: limit,
      categoryIds: categoryIds,
      specializationIds: specializationIds,
    );
  }

  Future<List<ContentItem>> getCourses({
    int limit = 10,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    return _getContentList(
      'courses',
      limit: limit,
      categoryIds: categoryIds,
      specializationIds: specializationIds,
    );
  }

  Future<List<ContentItem>> getEvents({
    int limit = 10,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    return _getContentList(
      'events',
      limit: limit,
      categoryIds: categoryIds,
      specializationIds: specializationIds,
    );
  }

  Future<List<ContentItem>> getPublications({
    int limit = 10,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    return _getContentList(
      'publications',
      limit: limit,
      categoryIds: categoryIds,
      specializationIds: specializationIds,
    );
  }

  Future<List<PublicationIssue>> getPublicationIssues(int publicationId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/publications/$publicationId/issues'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load publication issues: ${response.statusCode}',
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected publication issues response format');
      }

      final issues = decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => PublicationIssue.fromJson(json))
          .toList();
      if (kDebugMode) {
        for (final issue in issues) {
          debugPrint(
            'Publication issue PDF [list]: '
            'id=${issue.id}, issue.pdfUrl=${issue.pdfUrl}',
          );
        }
      }
      return issues;
    } catch (e) {
      debugPrint('Error fetching publication issues: $e');
      rethrow;
    }
  }

  Future<PublicationIssue> getPublicationIssueDetail(int issueId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/publication-issues/$issueId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw Exception('Publication issue not found');
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load publication issue: ${response.statusCode}',
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected publication issue response format');
      }

      final issue = PublicationIssue.fromJson(decoded);
      _logPublicationIssuePdf('detail', issue, decoded);
      return issue;
    } catch (e) {
      debugPrint('Error fetching publication issue detail: $e');
      rethrow;
    }
  }

  String getPublicationIssuePdfUrl(int issueId) {
    return '$_baseUrl/publication-issues/$issueId/pdf';
  }

  void _logPublicationIssuePdf(
    String source,
    PublicationIssue issue,
    Map<String, dynamic> json,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      'Publication issue PDF [$source]: '
      'id=${issue.id}, '
      'issue.pdfUrl=${issue.pdfUrl}, '
      'json.pdf_url=${json['pdf_url']}, '
      'json.issue_url=${json['issue_url']}, '
      'json.document_url=${json['document_url']}',
    );
  }

  Future<Map<String, String?>> getPublicationIssuePdfDiagnostics(
    int issueId,
  ) async {
    final url = getPublicationIssuePdfUrl(issueId);
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      final diagnostics = {
        'url': url,
        'statusCode': response.statusCode.toString(),
        'contentType': response.headers['content-type'],
        'contentLength': response.headers['content-length'],
        'acceptRanges': response.headers['accept-ranges'],
      };
      if (kDebugMode) {
        debugPrint('Publication issue PDF diagnostics: $diagnostics');
      }
      return diagnostics;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Publication issue PDF diagnostics failed: url=$url, $e');
      }
      return {'url': url, 'error': e.toString()};
    }
  }

  Future<List<ContentItem>> getNews({
    int limit = 10,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    return _getContentList(
      'news',
      limit: limit,
      categoryIds: categoryIds,
      specializationIds: specializationIds,
    );
  }

  Future<Map<String, dynamic>> getForYouRecommendations({
    int limit = 20,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final uri = Uri.parse(
        '$_baseUrl/for-you',
      ).replace(queryParameters: {'limit': limit.toString()});
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Nu am putut încărca recomandările personalizate.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Răspuns For You neașteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error fetching For You recommendations: $e');
      rethrow;
    }
  }

  Future<void> trackUserActivity({
    required String actionType,
    int? contentItemId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user-activity'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'action_type': actionType,
              if (contentItemId != null) 'content_item_id': contentItemId,
              'metadata': metadata ?? <String, dynamic>{},
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Activity tracking ignored: '
          '${_requestDiagnostics(url: response.request?.url.toString() ?? baseUrl, statusCode: response.statusCode, body: response.body)}',
        );
      }
    } catch (e) {
      debugPrint('Activity tracking ignored: $e');
    }
  }

  Future<bool> getFollowStatus({
    required String targetType,
    required int targetId,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final uri = Uri.parse('$_baseUrl/follows/status').replace(
        queryParameters: {
          'target_type': targetType,
          'target_id': targetId.toString(),
        },
      );
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut verifica follow-ul.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns follow neasteptat.');
      }
      return decoded['is_following'] == true;
    } catch (e) {
      debugPrint('Error fetching follow status: $e');
      rethrow;
    }
  }

  Future<void> followTarget({
    required String targetType,
    required int targetId,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/follows'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'target_type': targetType,
              'target_id': targetId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut adauga follow.'),
        );
      }
    } catch (e) {
      debugPrint('Error following target: $e');
      rethrow;
    }
  }

  Future<void> unfollowTarget({
    required String targetType,
    required int targetId,
  }) async {
    try {
      final headers = await _buildAuthHeaders();
      final uri = Uri.parse('$_baseUrl/follows').replace(
        queryParameters: {
          'target_type': targetType,
          'target_id': targetId.toString(),
        },
      );
      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut elimina follow.'),
        );
      }
    } catch (e) {
      debugPrint('Error unfollowing target: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFollows({String? targetType}) async {
    try {
      final headers = await _buildAuthHeaders();
      final uri = Uri.parse('$_baseUrl/follows').replace(
        queryParameters: {
          if (targetType != null && targetType.isNotEmpty)
            'target_type': targetType,
        },
      );
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut incarca follow-urile.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Raspuns follows neasteptat.');
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetching follows: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAuthorProfile(int authorId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/authors/$authorId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw Exception('Autorul nu a fost gasit.');
      }
      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(response, 'Nu am putut incarca autorul.'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns autor neasteptat.');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error fetching author profile: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getAuthorContent(
    int authorId, {
    int limit = 30,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/authors/$authorId/content',
      ).replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Nu am putut incarca materialele autorului.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Raspuns continut autor neasteptat.');
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => ContentItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching author content: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getContentItemDetail(int contentItemId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/content-items/$contentItemId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw Exception('Content item not found');
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to load content item: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        throw Exception(decoded['error']);
      }
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected content item response format');
      }

      return decoded;
    } catch (e) {
      debugPrint('Error fetching content item detail: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateAiSummaryResult(
    int contentItemId,
  ) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/content-items/$contentItemId/ai-summary'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Serviciul AI nu este disponibil momentan.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns AI neasteptat.');
      }

      final summary = decoded['summary'];
      if (summary is! String || summary.trim().isEmpty) {
        throw Exception('Serviciul AI nu este disponibil momentan.');
      }

      return decoded;
    } catch (e) {
      debugPrint('Error generating AI summary: $e');
      rethrow;
    }
  }

  Future<String> generateAiSummary(int contentItemId) async {
    final result = await generateAiSummaryResult(contentItemId);
    return result['summary'] as String;
  }

  Future<Map<String, dynamic>> generatePublicationIssueAiSummaryResult(
    int issueId,
  ) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/publication-issues/$issueId/ai-summary'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          _responseErrorMessage(
            response,
            'Rezumatul nu a putut fi generat. Încearcă din nou.',
          ),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Raspuns AI neasteptat.');
      }

      final summary = decoded['summary'];
      if (summary is! String || summary.trim().isEmpty) {
        throw Exception('Rezumatul nu a putut fi generat. Încearcă din nou.');
      }

      return decoded;
    } catch (e) {
      debugPrint('Error generating publication issue AI summary: $e');
      rethrow;
    }
  }

  Future<List<FilterOption>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/content-categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FilterOption.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<List<FilterOption>> getSpecializations() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/specializations'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FilterOption.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load specializations');
      }
    } catch (e) {
      debugPrint('Error fetching specializations: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getFeaturedContent({
    int limit = 3,
    List<int>? categoryIds,
    List<int>? specializationIds,
  }) async {
    return _getContentList(
      'featured-content',
      limit: limit,
      categoryIds: categoryIds,
      specializationIds: specializationIds,
    );
  }

  Future<Set<int>> getSavedContentIds() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/saved-content/ids'), headers: headers)
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load saved content ids: ${response.statusCode}',
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected saved ids response format');
      }

      return decoded.map((id) => int.parse(id.toString())).toSet();
    } catch (e) {
      debugPrint('Error fetching saved content ids: $e');
      rethrow;
    }
  }

  Future<void> saveContent(int contentItemId) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/saved-content/$contentItemId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception('Failed to save content: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving content: $e');
      rethrow;
    }
  }

  Future<void> unsaveContent(int contentItemId) async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/saved-content/$contentItemId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove saved content: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error removing saved content: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getSavedContent() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/saved-content'), headers: headers)
          .timeout(const Duration(seconds: 15));

      await _handleAuthFailure(response);
      if (response.statusCode != 200) {
        throw Exception('Failed to load saved content: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected saved content response format');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => ContentItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching saved content: $e');
      rethrow;
    }
  }

  Future<List<AdItem>> fetchAds({String? placement, int limit = 3}) async {
    try {
      final queryParameters = <String, String>{'limit': limit.toString()};
      if (placement != null && placement.isNotEmpty) {
        queryParameters['placement'] = placement;
      }

      final uri = Uri.parse(
        '$_baseUrl/ads',
      ).replace(queryParameters: queryParameters);
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Failed to load ads: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Unexpected ads response format');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => AdItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyTickets() async {
    final url = '$baseUrl/api/me/tickets';
    final headers = await _buildAuthHeaders();
    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw _friendlyNetworkException(error, 'incarcarea biletelor', url: url);
    }

    await _handleAuthFailure(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _responseErrorMessage(response, 'Eroare la incarcarea biletelor.'),
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Raspuns neasteptat pentru bilete.');
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }
}
