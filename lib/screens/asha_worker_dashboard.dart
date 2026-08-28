import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';
import '../widgets/language_picker.dart';
import 'high_risk_followup_screen.dart';
import 'patient_ehr_screen.dart';
import 'referral_tracking_screen.dart';

class AshaWorkerDashboard extends StatefulWidget {
  const AshaWorkerDashboard({super.key});

  @override
  State<AshaWorkerDashboard> createState() => _AshaWorkerDashboardState();
}

class _AshaWorkerDashboardState extends State<AshaWorkerDashboard> {
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Visit Kamala Devi (ANC check - 7th month)', 'done': false},
    {'title': 'Visit Raju (child immunization due)', 'done': false},
    {'title': 'Follow-up Shankar (diabetes medication)', 'done': false},
    {'title': 'Visit Meena (postnatal day 10)', 'done': false},
    {'title': 'New patient registration - Govind', 'done': false},
    {'title': 'Medicine distribution at Sub-Centre', 'done': false},
  ];

  final List<Map<String, String>> _recentActivity = [
    {'time': '9:30 AM', 'action': 'Registered new patient - Lakshmi Bai'},
    {'time': '9:00 AM', 'action': 'Completed ANC visit - Sita Devi'},
    {'time': 'Yesterday', 'action': 'Synced 12 records to server'},
    {'time': 'Yesterday', 'action': 'Referred Mohan to PHC (high BP)'},
    {'time': '2 days ago', 'action': 'Distributed iron tablets (15 patients)'},
  ];

  String _ashaName = '';
  int _households = 150;
  int _dueToday = 6;
  int _highRisk = 4;
  int _pending = 3;

  @override
  void initState() {
    super.initState();
    _loadAshaName();
    _fetchAshaData();
  }

  Future<void> _loadAshaName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ashaName = prefs.getString('ashaName') ?? 'ASHA Worker';
    });
  }

  Future<void> _fetchAshaData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/asha/1/patients'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _households = data.length > 0 ? data.length * 10 : 150;
          });
        }
      }

      final hrResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/high-risk'),
      );
      if (hrResponse.statusCode == 200) {
        final hrData = jsonDecode(hrResponse.body);
        if (hrData is List && hrData.isNotEmpty) {
          setState(() {
            _highRisk = hrData.length;
            _dueToday = hrData.where((p) => p['status'] == 'active').length;
          });
        }
      }
    } catch (_) {
      // Use defaults
    }
  }

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
            builder: (_) => page,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('asha_dashboard'.tr()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => LanguagePicker.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline sync banner
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'last_synced'.tr(),
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('syncing_data'.tr())),
                      );
                    },
                    icon: const Icon(Icons.sync, size: 18, color: Colors.teal),
                    label: Text('sync'.tr(), style: const TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Header card
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${'namaste'.tr()}, $_ashaName",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 4),
                  const Text("Village: Walani | Sub-Centre: Walani PHC"),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("$_households", 'households'.tr(), Icons.home),
                      _statItem("$_dueToday", 'due_today'.tr(), Icons.calendar_today),
                      _statItem("$_highRisk", 'high_risk'.tr(), Icons.warning),
                      _statItem("$_pending", 'pending'.tr(), Icons.pending_actions),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Today's Tasks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('todays_tasks'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _tasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return CheckboxListTile(
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      fontSize: 14,
                      decoration: task['done'] ? TextDecoration.lineThrough : null,
                      color: task['done'] ? Colors.grey : Colors.black87,
                    ),
                  ),
                  value: task['done'],
                  activeColor: Colors.teal,
                  onChanged: (val) {
                    setState(() {
                      _tasks[index]['done'] = val ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions (same UI as patient home screen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('quick_actions'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildFeatureItem(context,
              icon: Icons.person_add,
              title: 'register_new_patient'.tr(),
              page: PatientEHRScreen(),
              color: Colors.blue),
          _buildFeatureItem(context,
              icon: Icons.pregnant_woman,
              title: 'high_risk_followup'.tr(),
              page: HighRiskFollowUpScreen(),
              color: Colors.red),
          _buildFeatureItem(context,
              icon: Icons.swap_horiz,
              title: 'referral_tracking'.tr(),
              page: ReferralTrackingScreen(),
              color: Colors.deepOrange),
          _buildFeatureItem(context,
              icon: Icons.edit_note,
              title: 'record_visit'.tr(),
              page: PatientEHRScreen(),
              color: Colors.green),
          _buildFeatureItem(context,
              icon: Icons.schedule,
              title: 'schedule_followup'.tr(),
              page: HighRiskFollowUpScreen(),
              color: Colors.orange),
          _buildFeatureItem(context,
              icon: Icons.local_pharmacy,
              title: 'request_medicine'.tr(),
              page: PatientEHRScreen(),
              color: Colors.purple),

          const SizedBox(height: 16),

          // Recent Activity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('recent_activity'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _recentActivity.map((activity) {
                return ListTile(
                  leading: const Icon(Icons.circle, size: 8, color: Colors.teal),
                  title: Text(activity['action']!, style: const TextStyle(fontSize: 14)),
                  trailing: Text(
                    activity['time']!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  dense: true,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
