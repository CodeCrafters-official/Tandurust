import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'patientsignup.dart';
import 'doctor_login_screen.dart';
import 'loading_screen.dart';
import 'app_with_voice_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  // Your ngrok URL
  final String baseUrl = "https://ddc84add1485.ngrok-free.app";

  void _handleLogin({bool auto = false}) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter all fields")),
      );
      return;
    }

    // ✅ Hardcoded credentials
    final Map<String, String> hardcodedUsers = {
      "admin": "admin@123",
    };

    if (hardcodedUsers.containsKey(username) &&
        hardcodedUsers[username] == password) {
      // Save credentials locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);

      // Navigate to HomeScreen without API
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GlobalVoiceWrapper(child: HomeScreen()),
        ),
      );
      return;
    }

    // ✅ API call for patients if not hardcoded
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/patients/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save credentials locally
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        await prefs.setBool('isLoggedIn', true);

        // Navigate to HomeScreen with LoadingScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalVoiceWrapper(
              child: LoadingScreen(
                onLoadingComplete: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GlobalVoiceWrapper(child: HomeScreen()),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username or password")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to server: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("")),
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
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText
                      ? Icons.visibility_off
                      : Icons.visibility),
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
                child: const Text("Login"),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignUpPatientPage()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorLoginScreen()),
                );
              },
              child: const Text("Login as Doctor"),
            ),
          ],
        ),
      ),
    );
  }
}
