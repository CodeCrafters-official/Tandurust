import 'dart:async';
import 'package:flutter/material.dart';
import 'app_with_voice_button.dart'; // Import the global voice wrapper
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback? onLoadingComplete;

  const LoadingScreen({super.key, this.onLoadingComplete});
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
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
          // Use the callback if provided
          if (widget.onLoadingComplete != null) {
            widget.onLoadingComplete!();
          } else {
            // Default navigation to home screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      GlobalVoiceWrapper(child: HomeScreen())),
            );
          }
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
    return GlobalVoiceWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFB3E5FC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 600,
                height: 600,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
