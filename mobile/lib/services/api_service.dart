import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ad_item.dart';
import '../models/content_item.dart';
import '../models/filter_option.dart';
import 'auth_storage.dart';

class ApiService {
  static const String _defaultBaseUrl =
      'https://pulse-backend-5f9b.onrender.com';

  // Use --dart-define=PULSE_API_BASE_URL=... for local development.
  static String get baseUrl {
    const envBaseUrl = String.fromEnvironment('PULSE_API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    return _defaultBaseUrl;
  }

  final AuthStorage _authStorage = AuthStorage();

  Future<Map<String, String>> _buildAuthHeaders() async {
    final sessionToken = await _authStorage.getSessionToken();
    if (sessionToken == null || sessionToken.isEmpty) {
      throw Exception('No active session token');
    }
    return {
      'Authorization': 'Bearer $sessionToken',
    };
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final headers = await _buildAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/me/profile'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected profile response format');
      }
      return decoded;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
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
        '$baseUrl/$path',
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
          .get(Uri.parse('$baseUrl/health'))
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

  Future<Map<String, dynamic>> getContentItemDetail(int contentItemId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/content-items/$contentItemId'))
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

  Future<List<FilterOption>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/content-categories'));
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
      final response = await http.get(Uri.parse('$baseUrl/specializations'));
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
          .get(Uri.parse('$baseUrl/saved-content/ids'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to load saved content ids: ${response.statusCode}');
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
          .post(Uri.parse('$baseUrl/saved-content/$contentItemId'), headers: headers)
          .timeout(const Duration(seconds: 10));

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
          .delete(Uri.parse('$baseUrl/saved-content/$contentItemId'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to remove saved content: ${response.statusCode}');
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
          .get(Uri.parse('$baseUrl/saved-content'), headers: headers)
          .timeout(const Duration(seconds: 15));

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
        '$baseUrl/ads',
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
}
