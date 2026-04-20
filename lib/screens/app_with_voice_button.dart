import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'user_profile_screen.dart';
import 'social_connection_screen.dart';
import 'doctor_appointment_screen.dart';
import 'health_tips_screen.dart';
import 'news.dart';
import 'chatbot_screen.dart';
import 'settings_screen.dart';
import 'symptom_checker.dart';
import 'blood_bank_screen.dart';
import 'GovtSchemesScreen.dart';
import 'PatientReportsScreen.dart';
import 'patient_volunteer_screen.dart';
import 'medicine_info_screen.dart';
import 'first_aid_ai_screen.dart';
import 'appointment_management.dart';
import 'contacts_screen.dart';
import 'patientseveritymonitor.dart';
import 'consultation_history_screen.dart';

/// ✅ Wrap any screen with this to make mic appear globally
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
    // Add more voice commands as needed
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // The wrapped screen
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
