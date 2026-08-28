import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../widgets/language_picker.dart';
import 'doctor_loading_screen.dart';
import 'doctor_signup_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<Map<String, String>> _doctorCredentials = [
    {'username': 'doc', 'password': 'doc@123'},
  ];

  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isDoctorLoggedIn') ?? false;

    if (isLoggedIn) {
      String? savedUsername = prefs.getString('doctorUsername');
      String? savedPassword = prefs.getString('doctorPassword');

      if (savedUsername != null && savedPassword != null) {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;

        Future.delayed(Duration.zero, () {
          _handleLogin(auto: true);
        });
      }
    }
  }

  void _changeLanguage(BuildContext context) {
    LanguagePicker.show(context);
  }

  void _handleLogin({bool auto = false}) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('enter_all_fields'.tr())),
        );
      }
      return;
    }

    // Check hardcoded credentials first
    final matched = _doctorCredentials.any(
          (cred) => cred['username'] == username && cred['password'] == password,
    );

    if (matched) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDoctorLoggedIn', true);
      await prefs.setString('doctorUsername', username);
      await prefs.setString('doctorPassword', password);
      await prefs.setString('doctorName', 'Dr. Default');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DoctorLoadingScreen()),
      );
      return;
    }

    // Try API login
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctors/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDoctorLoggedIn', true);
        await prefs.setString('doctorUsername', username);
        await prefs.setString('doctorPassword', password);
        await prefs.setString('doctorName', data['doctor']?['name'] ?? username);
        await prefs.setInt('doctorId', data['doctor']?['id'] ?? 1);
        await prefs.setString('userRole', 'doctor');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DoctorLoadingScreen()),
        );
      } else if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid_credentials'.tr())),
        );
      }
    } catch (e) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid_credentials'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => _changeLanguage(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                width: 350,
                height: 350,
                child: Image.asset('assets/logo.png'),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'username'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
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
                    MaterialPageRoute(builder: (_) => const DoctorSignupScreen()),
                  );
                },
                child: Text('dont_have_account'.tr()),
              ),
            ],
          ),
        ),
    );
  }
}
