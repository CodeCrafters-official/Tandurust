import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguagePicker {
  static final List<Map<String, dynamic>> languages = [
    {'locale': const Locale('en'), 'name': 'English', 'native': 'English'},
    {'locale': const Locale('hi'), 'name': 'Hindi', 'native': 'हिन्दी'},
    {'locale': const Locale('ta'), 'name': 'Tamil', 'native': 'தமிழ்'},
    {'locale': const Locale('mr'), 'name': 'Marathi', 'native': 'मराठी'},
  ];

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = context.locale == lang['locale'];
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.teal : Colors.grey,
              ),
              title: Text(lang['native'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 18,
                  )),
              subtitle: Text(lang['name'] as String),
              onTap: () {
                context.setLocale(lang['locale'] as Locale);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
