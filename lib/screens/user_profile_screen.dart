import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String _role = 'patient';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString('userRole') ?? 'patient';

    try {
      if (_role == 'doctor') {
        final doctorId = prefs.getInt('doctorId') ?? 1;
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId'),
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          setState(() {
            _profile = jsonDecode(response.body);
            _isLoading = false;
          });
          return;
        }
      } else {
        final patientId = prefs.getInt('patientId') ?? 1;
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          setState(() {
            _profile = jsonDecode(response.body);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _profile = {
        'name': prefs.getString(_role == 'doctor' ? 'doctorName' : 'userName') ?? 'User',
        'username': prefs.getString(_role == 'doctor' ? 'doctorUsername' : 'username') ?? '',
        'phone': '',
        'village': '',
        'specialty': '',
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user_profile'.tr()),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal.shade200,
                    child: Icon(
                      _role == 'doctor' ? Icons.medical_services : Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profile?['name'] ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (_profile?['username'] != null)
                    Text('@${_profile!['username']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  if (_role == 'doctor' && _profile?['specialty'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text(_profile!['specialty']),
                        backgroundColor: Colors.teal.shade50,
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  if (_role == 'patient') _buildHealthCard(),
                  if (_role == 'doctor') _buildDoctorCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.phone, 'phone'.tr(), _profile?['phone'] ?? '-'),
            const Divider(),
            if (_role == 'patient') ...[
              _infoRow(Icons.location_on, 'village'.tr(), _profile?['village'] ?? '-'),
              const Divider(),
              _infoRow(Icons.cake, 'Age', _profile?['age']?.toString() ?? '-'),
              const Divider(),
              _infoRow(Icons.person_outline, 'Gender', _profile?['gender'] ?? '-'),
            ],
            if (_role == 'doctor') ...[
              _infoRow(Icons.local_hospital, 'specialty'.tr(), _profile?['specialty'] ?? '-'),
              const Divider(),
              _infoRow(Icons.work, 'experience'.tr(), '${_profile?['experience_years'] ?? '-'} ${'years'.tr()}'),
              const Divider(),
              _infoRow(Icons.circle,  'status'.tr(),
                  (_profile?['is_available'] == true) ? 'available'.tr() : 'busy'.tr()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('health_records'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 12),
            _infoRow(Icons.bloodtype, 'blood_type'.tr(), _profile?['blood_group'] ?? '-'),
            const Divider(),
            _infoRow(Icons.credit_card, 'abha_number'.tr(), _profile?['abha_id'] ?? '-'),
            const Divider(),
            _infoRow(Icons.medical_information, 'Chronic Conditions',
                _profile?['chronic_conditions'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              (_profile?['is_available'] == true) ? Icons.check_circle : Icons.cancel,
              color: (_profile?['is_available'] == true) ? Colors.green : Colors.red,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                (_profile?['is_available'] == true)
                    ? 'available'.tr()
                    : 'busy'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (_profile?['is_available'] == true) ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
