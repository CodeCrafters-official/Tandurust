import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class FacilityDashboardScreen extends StatefulWidget {
  const FacilityDashboardScreen({super.key});

  @override
  State<FacilityDashboardScreen> createState() =>
      _FacilityDashboardScreenState();
}

class _FacilityDashboardScreenState extends State<FacilityDashboardScreen> {
  String selectedFacility = 'CHC Shirpur';

  final List<String> facilities = [
    'Sub-Centre Mhow',
    'PHC Walani',
    'CHC Shirpur',
    'District Hospital Dhule',
  ];

  final Map<String, Map<String, dynamic>> facilityData = {
    'Sub-Centre Mhow': {
      'patientsToday': 18,
      'avgWait': 12,
      'bedOccupied': 4,
      'bedTotal': 6,
      'referralsPending': 2,
      'weeklyPatients': [12, 15, 18, 14, 16, 10, 8],
    },
    'PHC Walani': {
      'patientsToday': 34,
      'avgWait': 22,
      'bedOccupied': 8,
      'bedTotal': 15,
      'referralsPending': 4,
      'weeklyPatients': [28, 32, 30, 34, 29, 20, 15],
    },
    'CHC Shirpur': {
      'patientsToday': 67,
      'avgWait': 35,
      'bedOccupied': 22,
      'bedTotal': 30,
      'referralsPending': 7,
      'weeklyPatients': [55, 62, 58, 67, 60, 45, 38],
    },
    'District Hospital Dhule': {
      'patientsToday': 142,
      'avgWait': 48,
      'bedOccupied': 85,
      'bedTotal': 120,
      'referralsPending': 12,
      'weeklyPatients': [130, 138, 145, 142, 136, 110, 95],
    },
  };

  final List<Map<String, dynamic>> doctors = [
    {
      'name': 'Dr. Priya Patil',
      'specialty': 'General Medicine',
      'online': true,
      'currentPatients': 3
    },
    {
      'name': 'Dr. Rajesh Deshmukh',
      'specialty': 'Pediatrics',
      'online': true,
      'currentPatients': 2
    },
    {
      'name': 'Dr. Sunita Jadhav',
      'specialty': 'OB-GYN',
      'online': false,
      'currentPatients': 0
    },
    {
      'name': 'Dr. Amit Kulkarni',
      'specialty': 'Orthopedics',
      'online': true,
      'currentPatients': 1
    },
  ];

  final List<Map<String, dynamic>> medicines = [
    {'name': 'Paracetamol 500mg', 'stock': 85, 'unit': 'strips'},
    {'name': 'Amoxicillin 250mg', 'stock': 12, 'unit': 'strips'},
    {'name': 'ORS Packets', 'stock': 150, 'unit': 'packets'},
    {'name': 'Iron Tablets', 'stock': 8, 'unit': 'strips'},
    {'name': 'Insulin (Regular)', 'stock': 5, 'unit': 'vials'},
    {'name': 'Metformin 500mg', 'stock': 45, 'unit': 'strips'},
    {'name': 'Amlodipine 5mg', 'stock': 60, 'unit': 'strips'},
    {'name': 'Cetrizine 10mg', 'stock': 3, 'unit': 'strips'},
  ];

  final List<Map<String, dynamic>> equipment = [
    {'name': 'X-Ray Machine', 'status': 'Working', 'icon': Icons.medical_services},
    {
      'name': 'Blood Test Lab',
      'status': 'Busy',
      'icon': Icons.science,
    },
    {'name': 'ECG Machine', 'status': 'Working', 'icon': Icons.monitor_heart},
    {
      'name': 'Ultrasound',
      'status': 'Not Available',
      'icon': Icons.sensors,
    },
  ];

  final List<Map<String, dynamic>> pendingActions = [
    {
      'title': 'Accept referral: Suman Devi (PHC Walani)',
      'type': 'referral',
      'urgent': true
    },
    {
      'title': 'Accept referral: Raju Patil (Sub-Centre Mhow)',
      'type': 'referral',
      'urgent': true
    },
    {
      'title': 'Follow-up overdue: Anita Sharma (Diabetes)',
      'type': 'followup',
      'urgent': false
    },
    {
      'title': 'Follow-up overdue: Meena Bai (Maternal - 32 weeks)',
      'type': 'followup',
      'urgent': true
    },
    {
      'title': 'Stock reorder: Iron Tablets (critical low)',
      'type': 'stock',
      'urgent': true
    },
    {
      'title': 'Stock reorder: Insulin (critical low)',
      'type': 'stock',
      'urgent': true
    },
    {
      'title': 'Stock reorder: Cetrizine (low)',
      'type': 'stock',
      'urgent': false
    },
  ];

  Map<String, dynamic> get currentData => facilityData[selectedFacility]!;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/facilities'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            facilities.clear();
            for (var f in data) {
              final name = f['name'] as String;
              facilities.add(name);
              facilityData[name] = {
                'id': f['id'],
                'patientsToday': f['doctors_available'] != null ? f['doctors_available'] * 12 : 30,
                'avgWait': f['beds_total'] != null ? (f['beds_total'] * 1.5).toInt() : 20,
                'bedOccupied': f['beds_total'] != null ? f['beds_total'] - (f['beds_available'] ?? 0) : 10,
                'bedTotal': f['beds_total'] ?? 20,
                'referralsPending': 3,
                'weeklyPatients': [30, 35, 28, 40, 32, 25, 18],
              };
            }
            if (facilities.isNotEmpty) selectedFacility = facilities.first;
          });
          _fetchDashboardStats();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final id = facilityData[selectedFacility]?['id'];
      if (id == null) return;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/facilities/$id/dashboard'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          facilityData[selectedFacility] = {
            ...facilityData[selectedFacility]!,
            'patientsToday': data['patients_today'] ?? facilityData[selectedFacility]!['patientsToday'],
            'avgWait': data['avg_wait_minutes'] ?? facilityData[selectedFacility]!['avgWait'],
            'bedOccupied': data['beds_occupied'] ?? facilityData[selectedFacility]!['bedOccupied'],
            'bedTotal': data['beds_total'] ?? facilityData[selectedFacility]!['bedTotal'],
            'referralsPending': data['pending_referrals'] ?? facilityData[selectedFacility]!['referralsPending'],
          };
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('facility_dashboard'.tr()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchDashboardStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data refreshed')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFacilitySelector(),
          const SizedBox(height: 16),
          _buildMetricsRow(),
          const SizedBox(height: 20),
          _buildDoctorAvailability(),
          const SizedBox(height: 20),
          _buildMedicineStock(),
          const SizedBox(height: 20),
          _buildEquipmentStatus(),
          const SizedBox(height: 20),
          _buildWeeklyChart(),
          const SizedBox(height: 20),
          _buildPendingActions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFacilitySelector() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.local_hospital, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFacility,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  items: facilities
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedFacility = v!);
                    _fetchDashboardStats();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final data = currentData;
    final bedOcc = data['bedOccupied'] as int;
    final bedTot = data['bedTotal'] as int;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard(
          'Patients Today',
          '${data['patientsToday']}',
          Icons.people,
          Colors.blue,
        ),
        _statCard(
          'Avg Wait Time',
          '${data['avgWait']} min',
          Icons.timer,
          Colors.orange,
        ),
        _statCardWithProgress(
          'Bed Occupancy',
          '$bedOcc / $bedTot',
          Icons.bed,
          bedOcc / bedTot,
          bedOcc / bedTot > 0.8 ? Colors.red : Colors.green,
        ),
        _statCard(
          'Referrals Pending',
          '${data['referralsPending']}',
          Icons.swap_horiz,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCardWithProgress(
      String label, String value, IconData icon, double progress, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAvailability() {
    return _sectionCard(
      title: 'Doctor Availability',
      icon: Icons.medical_services,
      child: Column(
        children: doctors.map((doc) {
          final online = doc['online'] as bool;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: online ? Colors.green : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            title: Text(
              doc['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(doc['specialty']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: online ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (online)
                  Text(
                    '${doc['currentPatients']} patients',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicineStock() {
    final lowStock = medicines.where((m) => (m['stock'] as int) < 20).toList();
    final inStock = medicines.where((m) => (m['stock'] as int) >= 20).toList();

    return _sectionCard(
      title: 'Medicine Stock',
      icon: Icons.medication,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lowStock.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'LOW STOCK ALERTS',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...lowStock.map((m) => _medicineRow(m, low: true)),
            const Divider(height: 24),
          ],
          if (inStock.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'IN STOCK',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...inStock.map((m) => _medicineRow(m, low: false)),
          ],
        ],
      ),
    );
  }

  Widget _medicineRow(Map<String, dynamic> med, {required bool low}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: low ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: low ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            low ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: low ? Colors.red : Colors.green,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              med['name'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${med['stock']} ${med['unit']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: low ? Colors.red : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentStatus() {
    return _sectionCard(
      title: 'Equipment & Diagnostics',
      icon: Icons.biotech,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: equipment.map((eq) {
          final status = eq['status'] as String;
          Color color;
          if (status == 'Working') {
            color = Colors.green;
          } else if (status == 'Busy') {
            color = Colors.orange;
          } else {
            color = Colors.red;
          }

          return Container(
            width: (MediaQuery.of(context).size.width - 72) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Icon(eq['icon'] as IconData, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  eq['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final patients = currentData['weeklyPatients'] as List<int>;
    final maxVal = patients.reduce((a, b) => a > b ? a : b).toDouble();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _sectionCard(
      title: 'Patients Served This Week',
      icon: Icons.bar_chart,
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final height = maxVal > 0 ? (patients[i] / maxVal) * 100 : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${patients[i]}',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: i == 3
                            ? Colors.teal
                            : Colors.teal.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPendingActions() {
    return _sectionCard(
      title: 'Pending Actions',
      icon: Icons.assignment_late,
      child: Column(
        children: pendingActions.map((action) {
          IconData icon;
          Color color;
          switch (action['type']) {
            case 'referral':
              icon = Icons.swap_horiz;
              color = Colors.purple;
              break;
            case 'followup':
              icon = Icons.schedule;
              color = Colors.orange;
              break;
            default:
              icon = Icons.inventory;
              color = Colors.red;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: (action['urgent'] as bool)
                  ? Colors.red.shade50
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (action['urgent'] as bool)
                    ? Colors.red.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(icon, color: color, size: 22),
              title: Text(
                action['title'],
                style: const TextStyle(fontSize: 14),
              ),
              trailing: (action['urgent'] as bool)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
