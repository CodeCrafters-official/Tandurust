// lib/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  final String apiKey = '08d00aedf1c549c4a82ce4843c00d72b';  // Replace with your NewsAPI key
  final String baseUrl = 'https://newsapi.org/v2/top-headlines';

  // Fetch Indian news by setting the country parameter to 'in'
  Future<List<dynamic>> fetchNews() async {
    final response = await http.get(Uri.parse('$baseUrl?country=us&apiKey=$apiKey'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['articles'];
    } else {
      throw Exception('Failed to load news');
    }
  }
}
