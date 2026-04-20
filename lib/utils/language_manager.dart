import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageManager {
  static const String _key = "selected_language";

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  static Future<Locale> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_key);
    if (code != null) {
      return Locale(code);
    }
    return const Locale("en");
  }
}
