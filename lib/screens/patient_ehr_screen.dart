import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class PatientEHRScreen extends StatefulWidget {
  const PatientEHRScreen({super.key});

  @override
  State<PatientEHRScreen> createState() => _PatientEHRScreenState();
}

class _PatientEHRScreenState extends State<PatientEHRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    try {
      final patientsRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients'),
      ).timeout(const Duration(seconds: 5));

      if (patientsRes.statusCode == 200) {
        final List<dynamic> patients = jsonDecode(patientsRes.body);
        if (patients.isNotEmpty) {
          final p = patients[0];
          patient['name'] = p['name'] ?? patient['name'];
          patient['abhaId'] = p['abha_id'] ?? patient['abhaId'];
          patient['age'] = p['age'] ?? patient['age'];
          patient['gender'] = p['gender'] ?? patient['gender'];
          patient['bloodGroup'] = p['blood_group'] ?? patient['bloodGroup'];
          patient['village'] = p['village'] ?? patient['village'];
          if (p['chronic_conditions'] != null && p['chronic_conditions'].toString().isNotEmpty) {
            patient['chronicConditions'] = p['chronic_conditions'].toString().split(',');
          }

          final visitsRes = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/patients/${p['id']}/visits'),
          ).timeout(const Duration(seconds: 5));

          if (visitsRes.statusCode == 200) {
            final List<dynamic> visitData = jsonDecode(visitsRes.body);
            if (visitData.isNotEmpty) {
              visits = visitData.map((v) => <String, dynamic>{
                'date': v['visit_date']?.toString().substring(0, 10) ?? '',
                'facility': v['doctor_name'] ?? 'Unknown Facility',
                'facilityType': 'PHC',
                'doctor': v['doctor_name'] ?? 'Unknown',
                'specialty': 'General',
                'complaint': v['chief_complaint'] ?? '',
                'diagnosis': v['diagnosis'] ?? '',
                'prescription': v['prescription'] != null
                    ? (v['prescription'] as String).split(',')
                    : <String>[],
                'vitals': v['vitals_json'] != null
                    ? (jsonDecode(v['vitals_json']) as Map<String, dynamic>)
                    : {'HR': 72, 'BP': '120/80', 'SpO2': 98, 'Temp': 36.6},
                'notes': v['notes'] ?? '',
              }).toList();
              quickStats['totalVisits'] = visits.length;
            }
          }
        }
      }
    } catch (_) {
      // Fall back to mock data (already set below)
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // Mock patient data (fallback)
  final Map<String, dynamic> patient = {
    'name': 'Lakshmi Devi',
    'abhaId': 'ABHA-2024-78432',
    'age': 34,
    'gender': 'Female',
    'bloodGroup': 'B+',
    'phone': '+91 98765 43210',
    'village': 'Koregaon, Satara District',
    'chronicConditions': ['Gestational Diabetes', 'Anemia (Moderate)'],
  };

  final Map<String, dynamic> quickStats = {
    'totalVisits': 6,
    'activeMedications': 4,
    'pendingReferrals': 1,
    'nextFollowUp': '2026-09-03',
  };

  List<Map<String, dynamic>> visits = [
    {
      'date': '2026-08-25',
      'facility': 'District Hospital, Satara',
      'facilityType': 'DH',
      'doctor': 'Dr. Priya Kulkarni',
      'specialty': 'Obstetrician',
      'complaint': 'Referred for high-risk pregnancy monitoring',
      'diagnosis': 'Gestational diabetes - controlled, Anemia improving',
      'prescription': [
        'Insulin Glargine 10U SC at bedtime',
        'Iron Sucrose IV 200mg weekly x2',
        'Folic Acid 5mg OD',
        'Calcium 500mg BD',
      ],
      'vitals': {'HR': 78, 'BP': '126/82', 'SpO2': 98, 'Temp': 36.8},
      'notes': 'Fetal growth on track. Continue monitoring every 2 weeks.',
      'referredFrom': 'CHC Koregaon',
    },
    {
      'date': '2026-08-18',
      'facility': 'CHC Koregaon',
      'facilityType': 'CHC',
      'doctor': 'Dr. Anil Patil',
      'specialty': 'General Physician',
      'complaint': 'Follow-up for GDM, fatigue and pallor',
      'diagnosis': 'Gestational Diabetes Mellitus, Iron deficiency anemia',
      'prescription': [
        'Metformin 500mg BD (continued)',
        'Ferrous Fumarate 300mg OD',
        'Folic Acid 5mg OD',
      ],
      'vitals': {'HR': 84, 'BP': '132/86', 'SpO2': 97, 'Temp': 37.0},
      'notes': 'HbA1c elevated. Refer to DH for specialist management.',
      'referredTo': 'District Hospital, Satara',
    },
    {
      'date': '2026-08-04',
      'facility': 'CHC Koregaon',
      'facilityType': 'CHC',
      'doctor': 'Dr. Anil Patil',
      'specialty': 'General Physician',
      'complaint': 'Routine ANC visit - 24 weeks',
      'diagnosis': 'Pregnancy progressing, mild anemia detected',
      'prescription': [
        'Metformin 500mg BD',
        'Iron + Folic Acid tabs OD',
        'Calcium 500mg BD',
      ],
      'vitals': {'HR': 80, 'BP': '124/80', 'SpO2': 98, 'Temp': 36.7},
      'notes': 'GCT positive - started on Metformin. CBC shows Hb 9.2.',
      'referredFrom': 'PHC Umbraj',
    },
    {
      'date': '2026-07-20',
      'facility': 'PHC Umbraj',
      'facilityType': 'PHC',
      'doctor': 'Dr. Sanjay More',
      'specialty': 'MO (Medical Officer)',
      'complaint': 'ANC Registration + complaints of excessive thirst',
      'diagnosis': 'Suspected GDM, Advised GCT at CHC',
      'prescription': [
        'Folic Acid 400mcg OD',
        'Calcium 500mg OD',
      ],
      'vitals': {'HR': 76, 'BP': '118/76', 'SpO2': 99, 'Temp': 36.6},
      'notes': 'Registered for ANC. Polydipsia noted. Referred for GCT.',
      'referredTo': 'CHC Koregaon',
    },
    {
      'date': '2026-07-10',
      'facility': 'Sub-Centre, Koregaon Village',
      'facilityType': 'SC',
      'doctor': 'ANM Sunita Jadhav',
      'specialty': 'ASHA / ANM',
      'complaint': 'Pregnancy confirmation, first contact',
      'diagnosis': 'Intrauterine pregnancy ~18 weeks (LMP based)',
      'prescription': [
        'IFA tablets OD',
        'TT injection administered',
      ],
      'vitals': {'HR': 72, 'BP': '116/74', 'SpO2': 99, 'Temp': 36.5},
      'notes':
          'First ANC contact by ASHA worker. Referred to PHC for registration.',
      'referredTo': 'PHC Umbraj',
    },
    {
      'date': '2026-03-15',
      'facility': 'PHC Umbraj',
      'facilityType': 'PHC',
      'doctor': 'Dr. Sanjay More',
      'specialty': 'MO (Medical Officer)',
      'complaint': 'Fever, body ache for 3 days',
      'diagnosis': 'Viral fever',
      'prescription': [
        'Paracetamol 500mg TDS x 3 days',
        'ORS sachets',
      ],
      'vitals': {'HR': 88, 'BP': '110/70', 'SpO2': 98, 'Temp': 38.4},
      'notes': 'Symptomatic treatment. Follow up if no improvement in 3 days.',
    },
  ];

  final List<Map<String, dynamic>> labResults = [
    {
      'date': '2026-08-18',
      'test': 'HbA1c',
      'result': '6.8%',
      'normal': '<5.7%',
      'status': 'High',
      'facility': 'CHC Koregaon',
    },
    {
      'date': '2026-08-18',
      'test': 'Complete Blood Count (CBC)',
      'result': 'Hb: 9.8 g/dL',
      'normal': '12-16 g/dL',
      'status': 'Low',
      'facility': 'CHC Koregaon',
    },
    {
      'date': '2026-08-04',
      'test': 'Glucose Challenge Test (GCT)',
      'result': '168 mg/dL',
      'normal': '<140 mg/dL',
      'status': 'High',
      'facility': 'CHC Koregaon',
    },
    {
      'date': '2026-08-04',
      'test': 'CBC',
      'result': 'Hb: 9.2 g/dL',
      'normal': '12-16 g/dL',
      'status': 'Low',
      'facility': 'CHC Koregaon',
    },
    {
      'date': '2026-07-20',
      'test': 'Urine Routine',
      'result': 'Sugar: Trace',
      'normal': 'Nil',
      'status': 'Borderline',
      'facility': 'PHC Umbraj',
    },
    {
      'date': '2026-07-20',
      'test': 'Blood Group',
      'result': 'B Positive',
      'normal': '-',
      'status': 'Normal',
      'facility': 'PHC Umbraj',
    },
  ];

  final List<Map<String, dynamic>> referrals = [
    {
      'date': '2026-08-18',
      'from': 'CHC Koregaon',
      'to': 'District Hospital, Satara',
      'reason': 'High-risk pregnancy - GDM + Anemia for specialist care',
      'status': 'Completed',
      'completedDate': '2026-08-25',
    },
    {
      'date': '2026-08-04',
      'from': 'PHC Umbraj',
      'to': 'CHC Koregaon',
      'reason': 'GCT positive - needs physician management',
      'status': 'Completed',
      'completedDate': '2026-08-04',
    },
    {
      'date': '2026-07-20',
      'from': 'PHC Umbraj',
      'to': 'CHC Koregaon',
      'reason': 'GCT (Glucose Challenge Test) not available at PHC',
      'status': 'Completed',
      'completedDate': '2026-08-04',
    },
    {
      'date': '2026-07-10',
      'from': 'Sub-Centre, Koregaon Village',
      'to': 'PHC Umbraj',
      'reason': 'ANC registration and detailed checkup',
      'status': 'Completed',
      'completedDate': '2026-07-20',
    },
    {
      'date': '2026-08-25',
      'from': 'District Hospital, Satara',
      'to': 'CHC Koregaon',
      'reason': 'Fortnightly follow-up for GDM monitoring',
      'status': 'Pending',
      'scheduledDate': '2026-09-03',
    },
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _facilityColor(String type) {
    switch (type) {
      case 'SC':
        return Colors.green;
      case 'PHC':
        return Colors.blue;
      case 'CHC':
        return Colors.orange;
      case 'DH':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _facilityLabel(String type) {
    switch (type) {
      case 'SC':
        return 'Sub-Centre';
      case 'PHC':
        return 'Primary Health Centre';
      case 'CHC':
        return 'Community Health Centre';
      case 'DH':
        return 'District Hospital';
      default:
        return type;
    }
  }

  Widget _buildPatientHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.teal.shade700, Colors.teal.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Colors.teal.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          patient['abhaId'],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _infoChip(Icons.cake, '${patient['age']} yrs'),
                const SizedBox(width: 12),
                _infoChip(
                    Icons.person_outline, patient['gender']),
                const SizedBox(width: 12),
                _infoChip(Icons.bloodtype, patient['bloodGroup']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(Icons.location_on, patient['village']),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (patient['chronicConditions'] as List<String>)
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('${quickStats['totalVisits']}', 'Visits',
                Icons.history, Colors.blue),
            _statItem('${quickStats['activeMedications']}', 'Medications',
                Icons.medication, Colors.green),
            _statItem('${quickStats['pendingReferrals']}', 'Referrals',
                Icons.swap_horiz, Colors.orange),
            _statItem(
                quickStats['nextFollowUp'].toString().substring(5),
                'Next Visit',
                Icons.calendar_today,
                Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVisitsTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final facilityType = visit['facilityType'] as String;
        final color = _facilityColor(facilityType);
        final isLast = index == visits.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: color.withOpacity(0.3), width: 3),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              // Visit card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildVisitCard(visit, color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit, Color color) {
    final vitals = visit['vitals'] as Map<String, dynamic>;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(visit['date'].toString().substring(5),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(visit['date'].toString().substring(0, 4),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        title: Text(visit['facility'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                _facilityLabel(visit['facilityType']),
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Text('${visit['doctor']} (${visit['specialty']})',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        children: [
          const Divider(),
          _detailRow('Complaint', visit['complaint']),
          _detailRow('Diagnosis', visit['diagnosis']),
          const SizedBox(height: 8),
          // Vitals row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _vitalItem('HR', '${vitals['HR']}', 'bpm'),
                _vitalItem('BP', '${vitals['BP']}', 'mmHg'),
                _vitalItem('SpO2', '${vitals['SpO2']}', '%'),
                _vitalItem('Temp', '${vitals['Temp']}', '°C'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Prescription
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Prescription:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700)),
          ),
          const SizedBox(height: 4),
          ...(visit['prescription'] as List<String>).map((rx) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.teal.shade300),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(rx, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          if (visit['notes'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(visit['notes'],
                  style: TextStyle(
                      fontSize: 12, color: Colors.amber.shade900)),
            ),
          ],
          if (visit['referredTo'] != null || visit['referredFrom'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      visit['referredTo'] != null
                          ? 'Referred to: ${visit['referredTo']}'
                          : 'Referred from: ${visit['referredFrom']}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _vitalItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildPrescriptionsTab() {
    final allRx = <Map<String, dynamic>>[];
    for (var visit in visits) {
      for (var rx in (visit['prescription'] as List<String>)) {
        allRx.add({
          'medication': rx,
          'date': visit['date'],
          'doctor': visit['doctor'],
          'facility': visit['facility'],
        });
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allRx.length,
      itemBuilder: (context, index) {
        final rx = allRx[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: Icon(Icons.medication, color: Colors.teal.shade700),
            ),
            title: Text(rx['medication'],
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(
                '${rx['date']} | ${rx['doctor']}\n${rx['facility']}',
                style: const TextStyle(fontSize: 12)),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildLabResultsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: labResults.length,
      itemBuilder: (context, index) {
        final lab = labResults[index];
        Color statusColor;
        switch (lab['status']) {
          case 'High':
            statusColor = Colors.red;
            break;
          case 'Low':
            statusColor = Colors.orange;
            break;
          case 'Borderline':
            statusColor = Colors.amber.shade700;
            break;
          default:
            statusColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(lab['test'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(lab['status'],
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Result',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(lab['result'],
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Normal Range',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(lab['normal'],
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${lab['date']} | ${lab['facility']}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: referrals.length,
      itemBuilder: (context, index) {
        final ref = referrals[index];
        final isPending = ref['status'] == 'Pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isPending ? Colors.orange.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPending ? Icons.schedule : Icons.check_circle,
                      color: isPending ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ref['status'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(ref['date'],
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FROM',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600)),
                          Text(ref['from'],
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward,
                        color: Colors.teal.shade300, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TO',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600)),
                          Text(ref['to'],
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(ref['reason'],
                    style: const TextStyle(fontSize: 13, color: Colors.black87)),
                if (isPending && ref['scheduledDate'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('Scheduled: ${ref['scheduledDate']}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700)),
                    ],
                  ),
                ],
                if (!isPending && ref['completedDate'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Completed: ${ref['completedDate']}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.green.shade700)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_health_records'.tr()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Share via ABDM (Ayushman Bharat Digital Mission)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ABHA QR Code')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _buildPatientHeader(),
          ),
          // Quick Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _buildQuickStats(),
          ),
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.teal.shade700,
              indicator: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'visits'.tr()),
                Tab(text: 'prescriptions'.tr()),
                Tab(text: 'lab_results'.tr()),
                Tab(text: 'referrals'.tr()),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVisitsTimeline(),
                _buildPrescriptionsTab(),
                _buildLabResultsTab(),
                _buildReferralsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
