import 'dart:async';
import 'package:flutter/material.dart';
import 'doctor_home_screen.dart'; // Make sure to import your home screen
import 'app_with_voice_button.dart'; // Import your GlobalVoiceWrapper

class DoctorLoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<DoctorLoadingScreen> {
  int _loadingProgress = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(Duration(milliseconds: 25), (Timer timer) {
      setState(() {
        if (_loadingProgress < 100) {
          _loadingProgress++;
        } else {
          _timer.cancel();
          // After loading is complete, navigate to the home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DoctorHomeScreen()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalVoiceWrapper( // Wrap screen to add mic button
      child: Scaffold(
        backgroundColor: const Color(0xFFB3E5FC), // Lighter blue color
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo in the center
              Container(
                width: 600, // Adjust size as needed
                height: 600,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'), // Ensure your logo is correctly placed in assets
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Your Life, Our Priority!',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              CircularProgressIndicator(
                value: _loadingProgress / 100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading: $_loadingProgress%',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
