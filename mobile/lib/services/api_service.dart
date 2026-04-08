import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_item.dart';
import '../models/event_gallery_item.dart';

class ApiService {
  // Pentru local development:
  // - iOS Simulator / Web: http://127.0.0.1:8000
  // - Android Emulator: http://10.0.2.2:8000
  static const String _baseUrl = 'https://pulse-backend-5f9b.onrender.com';
  
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  Future<List<ContentItem>> getArticles({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/articles?limit=$limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching articles: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getCourses({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses?limit=$limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching courses: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getEvents({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/events?limit=$limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getPublications({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/publications?limit=$limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load publications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching publications: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getNews({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/news?limit=$limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      rethrow;
    }
  }

  Future<List<EventGalleryItem>> getEventGallery() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/event-gallery'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventGalleryItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load event gallery: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching event gallery: $e');
      rethrow;
    }
  }

  Future<List<ContentItem>> getFeaturedContent({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/featured-content?limit=$limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load featured content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching featured content: $e');
      rethrow;
    }
  }
}
