import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'user_profile_screen.dart';
import 'chatbot_screen.dart';
import 'settings_screen.dart';
import 'appointment_management.dart';
import 'contacts_screen.dart';
import 'patientseveritymonitor.dart';
import 'consultation_history_screen.dart';
import 'referral_tracking_screen.dart';
import 'teleconsultation_screen.dart';
import 'high_risk_followup_screen.dart';
import 'facility_dashboard_screen.dart';
import 'diagnostic_coordination_screen.dart';
import 'opd_queue_screen.dart';
import '../widgets/language_picker.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _doctorName = prefs.getString('doctorName') ?? 'Doctor';
    });
  }

  final List<Map<String, String>> todaysAppointments = [
    {'patient': 'Pavithra', 'time': '10:00 AM'},
    {'patient': 'Priyadharshini', 'time': '11:30 AM'},
    {'patient': 'Kausika', 'time': '02:00 PM'},
    {'patient': 'Arsath', 'time': '02:30 PM'},
    {'patient': 'Pradeepa', 'time': '03:30 PM'},
  ];

  final int pendingConsultations = 2;
  bool isAvailable = true;

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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
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

  Widget _buildDashboard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('status'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(children: [
                Text(isAvailable ? 'available'.tr() : 'busy'.tr(),
                    style: TextStyle(
                        color: isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
                Switch(
                  value: isAvailable,
                  onChanged: (v) => setState(() => isAvailable = v),
                )
              ])
            ],
          ),

          const SizedBox(height: 15),
          Text('todays_appointments'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          ...todaysAppointments.map((a) => ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: Text(a['patient']!),
            trailing: Text(a['time']!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          )),

          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.pending_actions, color: Colors.orange),
            const SizedBox(width: 10),
            Text("${'pending_consultations'.tr()}: $pendingConsultations")
          ])
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${'app_name'.tr()} - ${'doctor'.tr()}"),
          backgroundColor: Colors.teal,
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => LanguagePicker.show(context),
            ),
          ],
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),

        drawer: Drawer(
          child: ListView(
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
                      child: Icon(Icons.medical_services, size: 35, color: Colors.teal),
                    ),
                    const SizedBox(height: 10),
                    Text(_doctorName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _buildDrawerItem(context,
                  icon: Icons.person,
                  text: 'profile'.tr(),
                  page: UserProfileScreen()),
              _buildDrawerItem(context,
                  icon: Icons.settings,
                  text: 'settings'.tr(),
                  page: SettingsScreen()),
            ],
          ),
        ),

        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    "${'welcome'.tr()}, $_doctorName",
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),

                _buildDashboard(),

                _buildFeatureItem(context,
                  icon: Icons.monitor_heart,
                  title: 'patient_severity_monitor'.tr(),
                  page: EmergencyTriageBoardScreen(),
                  color: Colors.deepOrange,
                ),
                _buildFeatureItem(context,
                  icon: Icons.calendar_month,
                  title: 'appointment_management'.tr(),
                  page: AppointmentManagementScreen(),
                  color: Colors.redAccent,
                ),
                _buildFeatureItem(context,
                  icon: Icons.people,
                  title: 'patient_list'.tr(),
                  page: ContactsScreen(),
                  color: Colors.purple,
                ),
                _buildFeatureItem(context,
                  icon: Icons.history,
                  title: 'consultation_history'.tr(),
                  page: ConsultationHistoryScreen(),
                  color: Colors.indigo,
                ),
                _buildFeatureItem(context,
                  icon: Icons.video_call,
                  title: 'teleconsultation'.tr(),
                  page: TeleconsultationScreen(),
                  color: Colors.teal.shade700,
                ),
                _buildFeatureItem(context,
                  icon: Icons.swap_horiz,
                  title: 'referral_tracking'.tr(),
                  page: ReferralTrackingScreen(),
                  color: Colors.deepOrange,
                ),
                _buildFeatureItem(context,
                  icon: Icons.pregnant_woman,
                  title: 'high_risk_followup'.tr(),
                  page: HighRiskFollowUpScreen(),
                  color: Colors.red.shade700,
                ),
                _buildFeatureItem(context,
                  icon: Icons.dashboard,
                  title: 'facility_dashboard'.tr(),
                  page: FacilityDashboardScreen(),
                  color: Colors.blueGrey,
                ),
                _buildFeatureItem(context,
                  icon: Icons.science,
                  title: 'lab_diagnostics'.tr(),
                  page: DiagnosticCoordinationScreen(),
                  color: Colors.lime.shade800,
                ),
                _buildFeatureItem(context,
                  icon: Icons.queue,
                  title: 'opd_queue'.tr(),
                  page: OPDQueueScreen(),
                  color: Colors.cyan,
                ),
              ],
            ),

            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.teal,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen()),
                  );
                },
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
          ],
        ),
    );
  }
}

