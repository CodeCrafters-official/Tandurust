import 'package:flutter/material.dart';
import 'user_profile_screen.dart';
import 'chatbot_screen.dart';
import 'settings_screen.dart';
import 'appointment_management.dart';
import 'contacts_screen.dart';
import 'patientseveritymonitor.dart';
import 'consultation_history_screen.dart';
import 'patient_volunteer_screen.dart';
import 'pandemic_mode_screen.dart'; // 🚨 NEW IMPORT
import 'app_with_voice_button.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {

  final List<Map<String, String>> todaysAppointments = [
    {'patient': 'Pavithra', 'time': '10:00 AM'},
    {'patient': 'Priyadharshini', 'time': '11:30 AM'},
    {'patient': 'Kausika', 'time': '02:00 PM'},
    {'patient': 'Arsath', 'time': '02:30 PM'},
    {'patient': 'Pradeepa', 'time': '03:30 PM'},
  ];

  final int pendingConsultations = 2;
  bool isAvailable = true;

  // 🔹 Feature item builder
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

  // 🔹 Drawer item
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

  // 🔹 Dashboard card
  Widget _buildDashboard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          /// Availability toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(children: [
                Text(isAvailable ? "Available" : "Busy",
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
          const Text("Today's Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

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
            Text("Pending Consultations: $pendingConsultations")
          ])
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalVoiceWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tandurust Doctor"),
          backgroundColor: Colors.teal,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),

        /// Drawer
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.teal),
                child: Text("Menu",
                    style: TextStyle(color: Colors.white, fontSize: 22)),
              ),
              _buildDrawerItem(context,
                  icon: Icons.person,
                  text: "Profile",
                  page: UserProfileScreen()),
              _buildDrawerItem(context,
                  icon: Icons.settings,
                  text: "Settings",
                  page: SettingsScreen()),
            ],
          ),
        ),

        /// Body
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [

                _buildDashboard(),

                _buildFeatureItem(
                  context,
                  icon: Icons.monitor_heart,
                  title: "Patient Severity Monitor",
                  page: EmergencyTriageBoardScreen(),
                  color: Colors.deepOrange,
                ),

                _buildFeatureItem(
                  context,
                  icon: Icons.calendar_month,
                  title: "Appointment Management",
                  page: AppointmentManagementScreen(),
                  color: Colors.redAccent,
                ),

                _buildFeatureItem(
                  context,
                  icon: Icons.people,
                  title: "Patient List",
                  page: ContactsScreen(),
                  color: Colors.purple,
                ),

                _buildFeatureItem(
                  context,
                  icon: Icons.history,
                  title: "Consultation History",
                  page: ConsultationHistoryScreen(),
                  color: Colors.indigo,
                ),

                _buildFeatureItem(
                  context,
                  icon: Icons.volunteer_activism,
                  title: "Community Help",
                  page: PatientVolunteerScreen(),
                  color: Colors.pinkAccent,
                ),

                /// 🚨 NEW PANDEMIC PAGE
                _buildFeatureItem(
                  context,
                  icon: Icons.coronavirus,
                  title: "Pandemic Emergency Mode",
                  page: PandemicModeScreen(),
                  color: Colors.red,
                ),
              ],
            ),

            /// Chatbot FAB
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
      ),
    );
  }
}
