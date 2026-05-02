import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_item.dart';

class ApiService {
  // Pentru local development:
  // - iOS Simulator / Web: http://127.0.0.1:8000
  // - Android Emulator: http://10.0.2.2:8000
  static const String _baseUrl = String.fromEnvironment(
    'PULSE_API_BASE_URL',
    defaultValue: 'https://pulse-backend-5f9b.onrender.com',
  );

  Future<List<ContentItem>> _getContentList(
    String path, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$path',
      ).replace(queryParameters: {'limit': limit.toString()});
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

  Future<List<ContentItem>> getArticles({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/articles?limit=$limit'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching articles: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getCourses({int limit = 10}) async {
    return _getContentList('courses', limit: limit);
  }

  Future<List<ContentItem>> getEvents({int limit = 10}) async {
    return _getContentList('events', limit: limit);
  }

  Future<List<ContentItem>> getPublications({int limit = 10}) async {
    return _getContentList('publications', limit: limit);
  }

  Future<List<ContentItem>> getNews({int limit = 10}) async {
    return _getContentList('news', limit: limit);
  }

  Future<List<ContentItem>> getFeaturedContent({int limit = 3}) async {
    return _getContentList('featured-content', limit: limit);
  }
}
