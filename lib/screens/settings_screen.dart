import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/language_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.language, color: Colors.teal),
                    title: Text('select_language'.tr()),
                    subtitle: Text(_currentLanguageName()),
                    onTap: () => LanguagePicker.show(context),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                    title: const Text("Data & Privacy Policy"),
                    subtitle: const Text("View policies and consent"),
                    onTap: () {
                      _launchURL("https://example.com/privacy-policy");
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info, color: Colors.teal),
                    title: const Text("App Version"),
                    subtitle: const Text("1.0.0"),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.support_agent, color: Colors.teal),
                    title: const Text("Contact Support"),
                    subtitle: const Text("Email us for help"),
                    onTap: () {
                      _launchEmail("official.codecrafters.team@gmail.com");
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text('logout'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currentLanguageName() {
    final code = context.locale.languageCode;
    switch (code) {
      case 'hi': return 'हिन्दी';
      case 'ta': return 'தமிழ்';
      case 'mr': return 'मराठी';
      default: return 'English';
    }
  }
}
