import 'package:flutter/material.dart';
import 'app_with_voice_button.dart';
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
import 'contacts_screen.dart';
import 'DoctorRatingScreen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Map<String, dynamic>> doctors = [
    {
      'name': 'Dr. Ananya Sharma',
      'specialty': 'Cardiologist',
      'experience': 8,
      'status': true,
    },
    {
      'name': 'Dr. Rohan Mehta',
      'specialty': 'Neurologist',
      'experience': 12,
      'status': false,
    },
    {
      'name': 'Dr. Sneha Iyer',
      'specialty': 'Pediatrician',
      'experience': 5,
      'status': true,
    },
    {
      'name': 'Dr. Aditya Rao',
      'specialty': 'General Physician',
      'experience': 10,
      'status': true,
    },
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalVoiceWrapper(child: page),
          ),
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
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GlobalVoiceWrapper(child: page)),
        );
      },
    );
  }

  Widget _buildDoctorHeatmap(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Doctor Availability',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
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
                  color: doctor['status']
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: doctor['status'] ? Colors.green : Colors.red,
                      width: 2),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor:
                      doctor['status'] ? Colors.green : Colors.red,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(doctor['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
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
    return GlobalVoiceWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tandurust"),
          backgroundColor: Colors.teal,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.teal),
                child: Text("Menu",
                    style: TextStyle(color: Colors.white, fontSize: 22)),
              ),
              _buildDrawerItem(context,
                  icon: Icons.people,
                  text: 'User Profile',
                  page: UserProfileScreen()),
              _buildDrawerItem(context,
                  icon: Icons.newspaper, text: 'News', page: NewsPage()),
              _buildDrawerItem(context,
                  icon: Icons.settings,
                  text: 'Settings',
                  page: SettingsScreen()),
            ],
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDoctorHeatmap(context),

                _buildFeatureItem(
                  context,
                  icon: Icons.health_and_safety,
                  title: 'Symptom Check',
                  page: SymptomCheckerV2(),
                  color: Colors.redAccent,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.group,
                  title: 'Contact',
                  page: ContactsScreens(),
                  color: Colors.purple,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Doctor Appointment',
                  page: DoctorAppointmentScreen(),
                  color: Colors.orange,
                ),

                /// ⭐ NEW FEATURE ADDED HERE
                _buildFeatureItem(
                  context,
                  icon: Icons.star_rate,
                  title: 'Rate Doctor',
                  page: DoctorRatingScreen(),
                  color: Colors.amber,
                ),

                _buildFeatureItem(
                  context,
                  icon: Icons.assignment,
                  title: 'Report',
                  page: PatientReportsScreen(),
                  color: Colors.grey,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.lightbulb,
                  title: 'Health Tips',
                  page: HealthTipsScreen(),
                  color: Colors.yellow,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.bloodtype,
                  title: 'Blood Link',
                  page: BloodBankScreen(),
                  color: Colors.red,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.account_balance,
                  title: 'Government Schemes',
                  page: GovtSchemesScreen(),
                  color: Colors.indigo,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.volunteer_activism,
                  title: 'Community Help',
                  page: PatientVolunteerScreen(),
                  color: Colors.pinkAccent,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.local_pharmacy,
                  title: 'Medicine Info',
                  page: MedicineAvailabilityScreen(),
                  color: Colors.deepPurple,
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.medical_services,
                  title: 'First Aid',
                  page: FirstAidScreen(),
                  color: Colors.blue,
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
      ),
    );
  }
}
