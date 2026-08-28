import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class OfflineCache {
  static Future<dynamic> fetchWithCache(String endpoint, {Duration maxAge = const Duration(hours: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cache_$endpoint';
    final cacheTimeKey = 'cache_time_$endpoint';

    // Try API first
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save to cache
        await prefs.setString(cacheKey, response.body);
        await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
        return data;
      }
    } catch (_) {}

    // Fallback to cache
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }

    return null;
  }

  static Future<bool> postWithQueue(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // Queue for later sync
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList('offline_queue') ?? [];
      queue.add(jsonEncode({'endpoint': endpoint, 'data': data, 'timestamp': DateTime.now().toIso8601String()}));
      await prefs.setStringList('offline_queue', queue);
      return false;
    }
  }

  static Future<int> syncOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    if (queue.isEmpty) return 0;

    int synced = 0;
    final remaining = <String>[];

    for (final item in queue) {
      try {
        final parsed = jsonDecode(item);
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${parsed['endpoint']}'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(parsed['data']),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          synced++;
        } else {
          remaining.add(item);
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    await prefs.setStringList('offline_queue', remaining);
    return synced;
  }

  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('offline_queue') ?? []).length;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
