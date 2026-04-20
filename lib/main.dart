import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'screens/login_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/social_connection_screen.dart';
import 'screens/doctor_appointment_screen.dart';
import 'screens/health_tips_screen.dart';
import 'screens/news.dart';
import 'screens/chatbot_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/symptom_checker.dart';
import 'screens/blood_bank_screen.dart';
import 'screens/GovtSchemesScreen.dart';
import 'screens/PatientReportsScreen.dart';
import 'screens/patient_volunteer_screen.dart';
import 'screens/medicine_info_screen.dart';
import 'screens/first_aid_ai_screen.dart';
import 'screens/appointment_management.dart';
import 'screens/contacts_screen.dart';
import 'screens/patientseveritymonitor.dart';
import 'screens/consultation_history_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/doctor_loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/doctor_home_screen.dart';
import 'screens/doctor_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('pa'),
      ],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tandurust',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const GlobalVoiceWrapper(child: LoginPage()),
    );
  }
}

/// ✅ Global Wrapper that shows the mic button on ALL screens
class GlobalVoiceWrapper extends StatefulWidget {
  final Widget child;
  const GlobalVoiceWrapper({super.key, required this.child});

  @override
  State<GlobalVoiceWrapper> createState() => _GlobalVoiceWrapperState();
}

class _GlobalVoiceWrapperState extends State<GlobalVoiceWrapper> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _lastWords = val.recognizedWords;
        });

        if (val.hasConfidenceRating && val.confidence > 0) {
          _handleCommand(_lastWords.toLowerCase());
        }
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleCommand(String command) {
    if (command.contains('first aid') || command.contains('aid')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
            const GlobalVoiceWrapper(child: FirstAidScreen())),
      );
    } else if (command.contains('medicine') || command.contains('drug')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const GlobalVoiceWrapper(
                child: MedicineAvailabilityScreen())),
      );
    } else if (command.contains('symptom')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
            const GlobalVoiceWrapper(child: SymptomCheckerV2())),
      );
    }  else if (command.contains('medicine') || command.contains('drug')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const GlobalVoiceWrapper(
                child: MedicineAvailabilityScreen())),
      );
    } else if (command.contains('contact')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
            GlobalVoiceWrapper(child: ContactsScreens())),
      );
    } else if (command.contains('report')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child: PatientReportsScreen())),
      );
    } else if (command.contains('appointment')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child: DoctorAppointmentScreen())),
      );
    } else if (command.contains('tips')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child: HealthTipsScreen())),
      );
    } else if (command.contains('blood')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child: BloodBankScreen())),
      );
    } else if (command.contains('schemes')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child: GovtSchemesScreen())),
      );
    } else if (command.contains('community')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:PatientVolunteerScreen())),
      );
    } else if (command.contains('chat')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:ChatScreen())),
      );
    } else if (command.contains('news')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:NewsPage())),
      );
    } else if (command.contains('user profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:UserProfileScreen())),
      );
    } else if (command.contains('settings')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:SettingsScreen())),
      );
    } else if (command.contains('monitor')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:EmergencyTriageBoardScreen())),
      );
    } else if (command.contains('appointment management')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:AppointmentManagementScreen())),
      );
    } else if (command.contains('patient')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:ContactsScreen())),
      );
    } else if (command.contains('consultation')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GlobalVoiceWrapper(child:ConsultationHistoryScreen())),
      );
    }
    // Add more voice commands for other features
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // Your current screen
        Positioned(
          right: 20,
          top: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            onPressed: _isListening ? _stopListening : _startListening,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
