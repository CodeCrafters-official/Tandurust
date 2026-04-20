import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_with_voice_button.dart'; // Import your GlobalVoiceWrapper

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to LoginPage wrapped with GlobalVoiceWrapper
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalVoiceWrapper(
          child: const LoginPage(),
        ),
      ),
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
    return GlobalVoiceWrapper( // Wrap Settings screen itself
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: Colors.teal,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Data & Privacy Policy
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "About & Help",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal),
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
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.rate_review, color: Colors.teal),
                      title: const Text("Rate the App / Feedback"),
                      subtitle: const Text("Share your feedback"),
                      onTap: () {
                        _launchEmail("official.codecrafters.team@gmail.com");
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Logout button at bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
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
      ),
    );
  }
}
