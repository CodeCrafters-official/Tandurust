import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class ABDMHealthRecordsScreen extends StatefulWidget {
  const ABDMHealthRecordsScreen({super.key});

  @override
  State<ABDMHealthRecordsScreen> createState() =>
      _ABDMHealthRecordsScreenState();
}

class _ABDMHealthRecordsScreenState extends State<ABDMHealthRecordsScreen> {
  bool abhaLinked = true;

  Map<String, dynamic> abhaProfile = {
    'abhaNumber': '91-4832-7621-9045',
    'name': 'Rajesh Kumar',
    'gender': 'Male',
    'dob': '15-03-1985',
    'mobile': '+91 98XXX XXXXX',
  };

  @override
  void initState() {
    super.initState();
    _fetchPatientAbhaData();
  }

  Future<void> _fetchPatientAbhaData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients/1'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          abhaProfile = {
            'abhaNumber': data['abha_id'] ?? '91-4832-7621-9045',
            'name': data['name'] ?? 'Patient',
            'gender': data['gender'] ?? 'Unknown',
            'dob': '15-03-1985',
            'mobile': data['phone'] ?? '+91 98XXX XXXXX',
          };
        });
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> linkedFacilities = [
    {'name': 'PHC Walani', 'type': 'Primary Health Centre', 'linked': true},
    {'name': 'CHC Shirpur', 'type': 'Community Health Centre', 'linked': true},
    {
      'name': 'District Hospital Dhule',
      'type': 'District Hospital',
      'linked': true
    },
  ];

  final List<Map<String, dynamic>> healthRecords = [
    {
      'facility': 'PHC Walani',
      'date': '2026-08-20',
      'type': 'Prescription',
      'doctor': 'Dr. Meena Patil',
      'summary': 'Hypertension follow-up, Amlodipine 5mg continued',
    },
    {
      'facility': 'CHC Shirpur',
      'date': '2026-08-10',
      'type': 'Lab Report',
      'doctor': 'Dr. Suresh Joshi',
      'summary': 'HbA1c: 6.8%, Lipid Panel - LDL elevated',
    },
    {
      'facility': 'District Hospital Dhule',
      'date': '2026-07-25',
      'type': 'Discharge Summary',
      'doctor': 'Dr. Anil Sharma',
      'summary': 'Post appendectomy, recovery normal, sutures removed',
    },
    {
      'facility': 'PHC Walani',
      'date': '2026-06-15',
      'type': 'Immunization',
      'doctor': 'ANM Sunita',
      'summary': 'COVID-19 Booster (Covaxin) administered',
    },
    {
      'facility': 'CHC Shirpur',
      'date': '2026-05-02',
      'type': 'Prescription',
      'doctor': 'Dr. Kavita Deshmukh',
      'summary': 'Seasonal flu treatment, Paracetamol + antihistamine',
    },
  ];

  final List<Map<String, dynamic>> activeConsents = [
    {
      'requester': 'Dr. Meena Patil (PHC Walani)',
      'purpose': 'Ongoing treatment - Hypertension',
      'duration': '1 year (expires Mar 2027)',
      'status': 'active',
    },
    {
      'requester': 'District Hospital Dhule',
      'purpose': 'Post-surgery follow-up',
      'duration': '6 months (expires Jan 2027)',
      'status': 'active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('abdm_health_records'.tr()),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('syncing_abdm'.tr())),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAbhaCard(),
          const SizedBox(height: 20),
          _buildLinkedFacilities(),
          const SizedBox(height: 20),
          _buildHealthRecords(),
          const SizedBox(height: 20),
          _buildConsentManagement(),
          const SizedBox(height: 20),
          _buildStandardsInfo(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAbhaCard() {
    if (!abhaLinked) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.health_and_safety,
                  size: 48, color: Color(0xFF1565C0)),
              const SizedBox(height: 12),
              const Text(
                'Link your ABHA (Health ID)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect your Ayushman Bharat Health Account for seamless health record access across all facilities.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => abhaLinked = true),
                    icon: const Icon(Icons.link),
                    label: const Text('Link ABHA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => abhaLinked = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Create ABHA'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.health_and_safety,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ABHA Health Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2,
                      color: Color(0xFF1565C0), size: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              abhaProfile['abhaNumber'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              abhaProfile['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _abhaInfoChip(abhaProfile['gender']),
                const SizedBox(width: 12),
                _abhaInfoChip('DOB: ${abhaProfile['dob']}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  abhaProfile['mobile'],
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _abhaInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _buildLinkedFacilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Linked Facilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Scan facility QR or enter HFR ID to link')),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Link New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...linkedFacilities.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: const Icon(Icons.local_hospital,
                      color: Color(0xFF1565C0)),
                ),
                title: Text(f['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(f['type']),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            )),
      ],
    );
  }

  Widget _buildHealthRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Records',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Fetched from ABDM Health Information Exchange',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...healthRecords.map((r) => _buildRecordCard(r)),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    IconData typeIcon;
    Color typeColor;
    switch (record['type']) {
      case 'Prescription':
        typeIcon = Icons.medication;
        typeColor = Colors.teal;
        break;
      case 'Lab Report':
        typeIcon = Icons.science;
        typeColor = Colors.purple;
        break;
      case 'Discharge Summary':
        typeIcon = Icons.assignment_turned_in;
        typeColor = Colors.orange;
        break;
      case 'Immunization':
        typeIcon = Icons.vaccines;
        typeColor = Colors.green;
        break;
      default:
        typeIcon = Icons.description;
        typeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record['type'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                              fontSize: 15)),
                      Text(record['facility'],
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(record['date'],
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(record['doctor'],
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(record['summary'],
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(record['type']),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _detailRow('Facility', record['facility']),
                            _detailRow('Date', record['date']),
                            _detailRow('Doctor', record['doctor']),
                            _detailRow('Type', record['type']),
                            const Divider(),
                            const Text('Summary',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(record['summary']),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified,
                                      color: Color(0xFF1565C0), size: 16),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Digitally signed & verified via ABDM',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1565C0)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Full Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildConsentManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Consent Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Grant consent to a doctor or facility to access your records')),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Grant New'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Control who can access your health records',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...activeConsents.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF1565C0)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(c['requester'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text('Active',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _consentDetail(Icons.medical_information, c['purpose']),
                    _consentDetail(Icons.timer, c['duration']),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Consent revoked successfully')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Revoke'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _consentDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildStandardsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user,
                  color: Color(0xFF1565C0), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Interoperability Standards',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _standardItem('Records follow HL7 FHIR R4 standard'),
          _standardItem('Interoperable with all ABDM-connected facilities'),
          _standardItem('Data encrypted end-to-end (AES-256)'),
          _standardItem('Patient-controlled consent mechanism'),
        ],
      ),
    );
  }

  Widget _standardItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}
