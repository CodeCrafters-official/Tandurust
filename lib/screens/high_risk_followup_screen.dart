import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

enum RiskCategory { maternal, child, chronic }

enum RiskLevel { high, medium, low }

class HighRiskPatient {
  final String name;
  final int age;
  final String village;
  final RiskCategory category;
  final String condition;
  final RiskLevel riskLevel;
  final DateTime lastFollowUp;
  final DateTime nextFollowUp;
  final String ashaWorker;
  bool visited;

  HighRiskPatient({
    required this.name,
    required this.age,
    required this.village,
    required this.category,
    required this.condition,
    required this.riskLevel,
    required this.lastFollowUp,
    required this.nextFollowUp,
    required this.ashaWorker,
    this.visited = false,
  });
}

class HighRiskFollowUpScreen extends StatefulWidget {
  const HighRiskFollowUpScreen({super.key});

  @override
  State<HighRiskFollowUpScreen> createState() => _HighRiskFollowUpScreenState();
}

class _HighRiskFollowUpScreenState extends State<HighRiskFollowUpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<HighRiskPatient> _patients = [
    HighRiskPatient(
      name: 'Sunita Devi',
      age: 26,
      village: 'Rampur',
      category: RiskCategory.maternal,
      condition: 'High-risk pregnancy - Gestational diabetes',
      riskLevel: RiskLevel.high,
      lastFollowUp: DateTime(2026, 8, 15),
      nextFollowUp: DateTime(2026, 8, 22),
      ashaWorker: 'Meena Kumari',
    ),
    HighRiskPatient(
      name: 'Kavita Sharma',
      age: 32,
      village: 'Devgadh',
      category: RiskCategory.maternal,
      condition: 'Pre-eclampsia risk - 3rd trimester',
      riskLevel: RiskLevel.high,
      lastFollowUp: DateTime(2026, 8, 20),
      nextFollowUp: DateTime(2026, 8, 27),
      ashaWorker: 'Rekha Bai',
    ),
    HighRiskPatient(
      name: 'Baby Arjun (S/o Priya)',
      age: 1,
      village: 'Khandwa',
      category: RiskCategory.child,
      condition: 'Malnutrition - Severe underweight (SAM)',
      riskLevel: RiskLevel.high,
      lastFollowUp: DateTime(2026, 8, 10),
      nextFollowUp: DateTime(2026, 8, 20),
      ashaWorker: 'Meena Kumari',
    ),
    HighRiskPatient(
      name: 'Baby Riya (D/o Suman)',
      age: 2,
      village: 'Rampur',
      category: RiskCategory.child,
      condition: 'Recurrent pneumonia - Immunocompromised',
      riskLevel: RiskLevel.medium,
      lastFollowUp: DateTime(2026, 8, 18),
      nextFollowUp: DateTime(2026, 8, 28),
      ashaWorker: 'Anita Devi',
    ),
    HighRiskPatient(
      name: 'Ramesh Patil',
      age: 58,
      village: 'Shirpur',
      category: RiskCategory.chronic,
      condition: 'Type 2 Diabetes - Uncontrolled HbA1c 9.2',
      riskLevel: RiskLevel.high,
      lastFollowUp: DateTime(2026, 8, 5),
      nextFollowUp: DateTime(2026, 8, 19),
      ashaWorker: 'Rekha Bai',
    ),
    HighRiskPatient(
      name: 'Lata Bhosale',
      age: 62,
      village: 'Devgadh',
      category: RiskCategory.chronic,
      condition: 'Hypertension Stage 2 + CKD',
      riskLevel: RiskLevel.high,
      lastFollowUp: DateTime(2026, 8, 12),
      nextFollowUp: DateTime(2026, 8, 26),
      ashaWorker: 'Anita Devi',
    ),
    HighRiskPatient(
      name: 'Meera Jadhav',
      age: 29,
      village: 'Khandwa',
      category: RiskCategory.maternal,
      condition: 'Previous stillbirth - Close monitoring',
      riskLevel: RiskLevel.medium,
      lastFollowUp: DateTime(2026, 8, 22),
      nextFollowUp: DateTime(2026, 8, 29),
      ashaWorker: 'Meena Kumari',
    ),
    HighRiskPatient(
      name: 'Ganesh Wagh',
      age: 45,
      village: 'Shirpur',
      category: RiskCategory.chronic,
      condition: 'Tuberculosis - MDR, on DOTS',
      riskLevel: RiskLevel.medium,
      lastFollowUp: DateTime(2026, 8, 24),
      nextFollowUp: DateTime(2026, 8, 31),
      ashaWorker: 'Rekha Bai',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchHighRiskPatients();
  }

  Future<void> _fetchHighRiskPatients() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/high-risk'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final List<HighRiskPatient> fetched = data.map((item) {
            RiskCategory cat;
            switch (item['category']) {
              case 'maternal': cat = RiskCategory.maternal; break;
              case 'child': cat = RiskCategory.child; break;
              default: cat = RiskCategory.chronic;
            }
            RiskLevel lvl;
            switch (item['risk_level']) {
              case 'high': lvl = RiskLevel.high; break;
              case 'medium': lvl = RiskLevel.medium; break;
              default: lvl = RiskLevel.low;
            }
            return HighRiskPatient(
              name: item['patient_name'] ?? item['condition_details'] ?? 'Unknown',
              age: item['patient_age'] ?? 0,
              village: item['patient_village'] ?? '',
              category: cat,
              condition: item['condition_details'] ?? '',
              riskLevel: lvl,
              lastFollowUp: item['last_followup_date'] != null
                  ? DateTime.tryParse(item['last_followup_date']) ?? DateTime.now()
                  : DateTime.now(),
              nextFollowUp: item['next_followup_date'] != null
                  ? DateTime.tryParse(item['next_followup_date']) ?? DateTime.now()
                  : DateTime.now(),
              ashaWorker: item['asha_worker_name'] ?? '',
              visited: item['status'] == 'resolved',
            );
          }).toList();
          setState(() {
            _patients.clear();
            _patients.addAll(fetched);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _postHighRiskPatient(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/high-risk'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      _fetchHighRiskPatients();
    } catch (_) {}
  }

  Future<void> _markVisited(int index) async {
    setState(() {
      _patients[index].visited = true;
    });
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/high-risk/${index + 1}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "last_followup_date": DateTime.now().toIso8601String().split('T')[0],
          "next_followup_date": DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T')[0],
          "status": "active",
        }),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _today => DateTime(2026, 8, 27);

  bool _isOverdue(HighRiskPatient p) =>
      p.nextFollowUp.isBefore(_today) && !p.visited;

  bool _isDueToday(HighRiskPatient p) =>
      p.nextFollowUp.year == _today.year &&
      p.nextFollowUp.month == _today.month &&
      p.nextFollowUp.day == _today.day &&
      !p.visited;

  bool _isUpcomingThisWeek(HighRiskPatient p) {
    final end = _today.add(const Duration(days: 7));
    return p.nextFollowUp.isAfter(_today) &&
        p.nextFollowUp.isBefore(end) &&
        !p.visited;
  }

  List<HighRiskPatient> _filteredPatients(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _patients
            .where((p) => p.category == RiskCategory.maternal)
            .toList();
      case 2:
        return _patients
            .where((p) => p.category == RiskCategory.child)
            .toList();
      case 3:
        return _patients
            .where((p) => p.category == RiskCategory.chronic)
            .toList();
      default:
        return _patients;
    }
  }

  String _categoryLabel(RiskCategory cat) {
    switch (cat) {
      case RiskCategory.maternal:
        return 'Maternal';
      case RiskCategory.child:
        return 'Child';
      case RiskCategory.chronic:
        return 'Chronic';
    }
  }

  String _categoryEmoji(RiskCategory cat) {
    switch (cat) {
      case RiskCategory.maternal:
        return '\u{1F930}';
      case RiskCategory.child:
        return '\u{1F476}';
      case RiskCategory.chronic:
        return '\u{1F48A}';
    }
  }

  Color _categoryColor(RiskCategory cat) {
    switch (cat) {
      case RiskCategory.maternal:
        return Colors.pink;
      case RiskCategory.child:
        return Colors.blue;
      case RiskCategory.chronic:
        return Colors.deepPurple;
    }
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.low:
        return Colors.green;
    }
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.medium:
        return 'MEDIUM';
      case RiskLevel.low:
        return 'LOW';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _markPatientVisited(HighRiskPatient patient) {
    final index = _patients.indexOf(patient);
    setState(() {
      patient.visited = true;
    });
    if (index >= 0) _markVisited(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${patient.name} marked as visited'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final villageCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();
    RiskCategory selectedCategory = RiskCategory.maternal;
    RiskLevel selectedRisk = RiskLevel.high;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Register High-Risk Patient'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Patient Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: villageCtrl,
                  decoration: const InputDecoration(labelText: 'Village'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RiskCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: RiskCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(c)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RiskLevel>(
                  value: selectedRisk,
                  decoration: const InputDecoration(labelText: 'Risk Level'),
                  items: RiskLevel.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(_riskLabel(r)),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedRisk = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                if (nameCtrl.text.isEmpty || ageCtrl.text.isEmpty) return;
                setState(() {
                  _patients.add(HighRiskPatient(
                    name: nameCtrl.text,
                    age: int.tryParse(ageCtrl.text) ?? 0,
                    village: villageCtrl.text,
                    category: selectedCategory,
                    condition: conditionCtrl.text,
                    riskLevel: selectedRisk,
                    lastFollowUp: _today,
                    nextFollowUp: _today.add(const Duration(days: 7)),
                    ashaWorker: 'Unassigned',
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final overdue = _patients.where(_isOverdue).length;
    final dueToday = _patients.where(_isDueToday).length;
    final upcoming = _patients.where(_isUpcomingThisWeek).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _summaryCard('Total', _patients.length, Colors.teal),
          _summaryCard('Overdue', overdue, Colors.red),
          _summaryCard('Today', dueToday, Colors.orange),
          _summaryCard('This Week', upcoming, Colors.green),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(HighRiskPatient patient) {
    final overdue = _isOverdue(patient);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _categoryColor(patient.category).withOpacity(0.15),
                  child: Text(
                    _categoryEmoji(patient.category),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Age: ${patient.age} | ${patient.village}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor(patient.riskLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _riskColor(patient.riskLevel)),
                  ),
                  child: Text(
                    _riskLabel(patient.riskLevel),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _riskColor(patient.riskLevel),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _categoryColor(patient.category).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _categoryColor(patient.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _categoryLabel(patient.category),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _categoryColor(patient.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      patient.condition,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.history, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  'Last: ${_formatDate(patient.lastFollowUp)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.event,
                  size: 14,
                  color: overdue ? Colors.red : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next: ${_formatDate(patient.nextFollowUp)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                    color: overdue ? Colors.red : Colors.black54,
                  ),
                ),
                if (overdue) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_pin, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text(
                  'ASHA: ${patient.ashaWorker}',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${patient.name}...')),
                    );
                  },
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Scheduling visit for ${patient.name}')),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Schedule',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: patient.visited
                      ? null
                      : () => _markPatientVisited(patient),
                  icon: Icon(
                    patient.visited ? Icons.check_circle : Icons.check,
                    size: 16,
                  ),
                  label: Text(
                    patient.visited ? 'Done' : 'Mark Visited',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        patient.visited ? Colors.grey : Colors.teal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('high_risk_followup'.tr()),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'all'.tr()),
            Tab(text: 'maternal'.tr()),
            Tab(text: 'child'.tr()),
            Tab(text: 'chronic'.tr()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPatientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIndex) {
                final patients = _filteredPatients(tabIndex);
                if (patients.isEmpty) {
                  return const Center(
                    child: Text('No patients in this category'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: patients.length,
                  itemBuilder: (context, index) =>
                      _buildPatientCard(patients[index]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
