import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'user_profile_screen.dart';
import 'doctor_appointment_screen.dart';
import 'health_tips_screen.dart';
import 'chatbot_screen.dart';
import 'settings_screen.dart';
import 'symptom_checker.dart';
import 'blood_bank_screen.dart';
import 'GovtSchemesScreen.dart';
import 'medicine_info_screen.dart';
import 'first_aid_ai_screen.dart';
import 'referral_tracking_screen.dart';
import 'patient_ehr_screen.dart';
import 'teleconsultation_screen.dart';
import 'opd_queue_screen.dart';
import 'abdm_health_records_screen.dart';
import 'notifications_screen.dart';
import '../widgets/language_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  final List<Map<String, dynamic>> doctors = [
    {'name': 'Dr. Ananya Sharma', 'specialty': 'Cardiologist', 'experience': 8, 'status': true},
    {'name': 'Dr. Rohan Mehta', 'specialty': 'Neurologist', 'experience': 12, 'status': false},
    {'name': 'Dr. Sneha Iyer', 'specialty': 'Pediatrician', 'experience': 5, 'status': true},
    {'name': 'Dr. Aditya Rao', 'specialty': 'General Physician', 'experience': 10, 'status': true},
  ];

  Widget _buildFeatureItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Widget page,
        required Color color,
      }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(text),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }

  Widget _buildDoctorHeatmap(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'doctor_availability'.tr(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: doctor['status'] ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: doctor['status'] ? Colors.green : Colors.red, width: 2),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: doctor['status'] ? Colors.green : Colors.red,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(doctor['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(doctor['specialty'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => LanguagePicker.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.teal),
                  ),
                  const SizedBox(height: 10),
                  Text(_userName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDrawerItem(context,
                icon: Icons.people, text: 'user_profile'.tr(), page: UserProfileScreen()),
            _buildDrawerItem(context,
                icon: Icons.settings, text: 'settings'.tr(), page: SettingsScreen()),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "${'welcome'.tr()}, $_userName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
          _buildDoctorHeatmap(context),

          // === CORE FEATURES (SIH PS 26133) ===
          _buildFeatureItem(context,
            icon: Icons.health_and_safety,
            title: 'symptom_check'.tr(),
            page: SymptomCheckerV2(),
            color: Colors.redAccent,
          ),
          _buildFeatureItem(context,
            icon: Icons.video_call,
            title: 'teleconsultation'.tr(),
            page: TeleconsultationScreen(),
            color: Colors.teal,
          ),
          _buildFeatureItem(context,
            icon: Icons.swap_horiz,
            title: 'referral_tracking'.tr(),
            page: ReferralTrackingScreen(),
            color: Colors.deepOrange,
          ),
          _buildFeatureItem(context,
            icon: Icons.folder_shared,
            title: 'my_health_records'.tr(),
            page: PatientEHRScreen(),
            color: Colors.brown,
          ),
          _buildFeatureItem(context,
            icon: Icons.credit_card,
            title: 'abha_health_id'.tr(),
            page: ABDMHealthRecordsScreen(),
            color: Colors.blue.shade800,
          ),
          _buildFeatureItem(context,
            icon: Icons.queue,
            title: 'opd_queue'.tr(),
            page: OPDQueueScreen(),
            color: Colors.cyan,
          ),
          _buildFeatureItem(context,
            icon: Icons.calendar_today,
            title: 'doctor_appointment'.tr(),
            page: DoctorAppointmentScreen(),
            color: Colors.orange,
          ),

          const Divider(height: 32),

          // === ADDITIONAL FEATURES ===
          _buildFeatureItem(context,
            icon: Icons.medical_services,
            title: 'first_aid'.tr(),
            page: FirstAidScreen(),
            color: Colors.blue,
          ),
          _buildFeatureItem(context,
            icon: Icons.local_pharmacy,
            title: 'medicine_info'.tr(),
            page: MedicineAvailabilityScreen(),
            color: Colors.deepPurple,
          ),
          _buildFeatureItem(context,
            icon: Icons.lightbulb,
            title: 'health_tips'.tr(),
            page: HealthTipsScreen(),
            color: Colors.amber,
          ),
          _buildFeatureItem(context,
            icon: Icons.bloodtype,
            title: 'blood_link'.tr(),
            page: BloodBankScreen(),
            color: Colors.red,
          ),
          _buildFeatureItem(context,
            icon: Icons.account_balance,
            title: 'govt_schemes'.tr(),
            page: GovtSchemesScreen(),
            color: Colors.indigo,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
        },
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
