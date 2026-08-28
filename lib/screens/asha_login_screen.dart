import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';
import '../widgets/language_picker.dart';
import 'asha_worker_dashboard.dart';
import 'asha_signup_screen.dart';

class AshaLoginScreen extends StatefulWidget {
  const AshaLoginScreen({super.key});

  @override
  State<AshaLoginScreen> createState() => _AshaLoginScreenState();
}

class _AshaLoginScreenState extends State<AshaLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter_all_fields'.tr())),
      );
      return;
    }

    // Hardcoded fallback
    final Map<String, String> hardcodedUsers = {
      "asha1": "asha@123",
    };

    if (hardcodedUsers.containsKey(username) &&
        hardcodedUsers[username] == password) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('ashaName', 'Sunita Pawar');
      await prefs.setString('userRole', 'asha');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AshaWorkerDashboard(),
        ),
      );
      return;
    }

    // Try API login
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/asha/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('ashaName', data['worker']?['name'] ?? username);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AshaWorkerDashboard(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid_credentials'.tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_credentials'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('asha_worker_login'.tr()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => LanguagePicker.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: Image.asset('assets/logo.png'),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'username'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: 'password'.tr(),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogin,
                child: Text('login'.tr()),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AshaSignupScreen()),
                );
              },
              child: Text('dont_have_account'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('back_to_patient_login'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
