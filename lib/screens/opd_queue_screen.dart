import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class OPDQueueScreen extends StatefulWidget {
  const OPDQueueScreen({super.key});

  @override
  State<OPDQueueScreen> createState() => _OPDQueueScreenState();
}

class _OPDQueueScreenState extends State<OPDQueueScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedDepartment = 'General OPD';
  String _selectedDoctor = 'Any Available';

  int? _myToken;
  int _nextTokenCounter = 15;

  final List<String> departments = [
    'General OPD',
    'Pediatrics',
    'Gynecology',
    'Orthopedics',
    'Eye',
    'Dental',
  ];

  final Map<String, List<String>> doctorsByDept = {
    'General OPD': ['Any Available', 'Dr. Aditya Rao', 'Dr. Meera Joshi'],
    'Pediatrics': ['Any Available', 'Dr. Sneha Iyer'],
    'Gynecology': ['Any Available', 'Dr. Kavitha Nair'],
    'Orthopedics': ['Any Available', 'Dr. Rohan Mehta'],
    'Eye': ['Any Available', 'Dr. Priya Deshmukh'],
    'Dental': ['Any Available', 'Dr. Sanjay Kulkarni'],
  };

  final List<Map<String, dynamic>> _queueData = [
    {
      'department': 'General OPD',
      'currentlyServing': 9,
      'avgTime': 8,
      'waiting': [
        {'token': 10, 'name': 'Ramesh K.'},
        {'token': 11, 'name': 'Sunita D.'},
        {'token': 12, 'name': 'Arjun P.'},
        {'token': 13, 'name': 'Meena S.'},
        {'token': 14, 'name': 'Vijay T.'},
      ],
    },
    {
      'department': 'Pediatrics',
      'currentlyServing': 5,
      'avgTime': 12,
      'waiting': [
        {'token': 6, 'name': 'Baby Ananya'},
        {'token': 7, 'name': 'Rohan (child)'},
      ],
    },
    {
      'department': 'Gynecology',
      'currentlyServing': 3,
      'avgTime': 15,
      'waiting': [
        {'token': 4, 'name': 'Lakshmi R.'},
        {'token': 5, 'name': 'Priya M.'},
        {'token': 6, 'name': 'Geeta B.'},
      ],
    },
    {
      'department': 'Orthopedics',
      'currentlyServing': 7,
      'avgTime': 10,
      'waiting': [
        {'token': 8, 'name': 'Suresh V.'},
      ],
    },
    {
      'department': 'Eye',
      'currentlyServing': 4,
      'avgTime': 6,
      'waiting': [
        {'token': 5, 'name': 'Kamala D.'},
        {'token': 6, 'name': 'Raju N.'},
        {'token': 7, 'name': 'Asha W.'},
        {'token': 8, 'name': 'Bharat S.'},
      ],
    },
    {
      'department': 'Dental',
      'currentlyServing': 2,
      'avgTime': 20,
      'waiting': [
        {'token': 3, 'name': 'Dinesh G.'},
      ],
    },
  ];

  void _getToken() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient name')),
      );
      return;
    }

    final patientName = _nameController.text.trim();

    // Try backend first
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/queue/check-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_name': patientName,
          'department': _selectedDepartment,
          'doctor_name': _selectedDoctor == 'Any Available' ? null : _selectedDoctor,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _myToken = data['token_number'];
          _nextTokenCounter = _myToken! + 1;
          final deptQueue = _queueData.firstWhere(
            (q) => q['department'] == _selectedDepartment,
          );
          (deptQueue['waiting'] as List).add({
            'token': _myToken,
            'name': patientName,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token #$_myToken assigned for $_selectedDepartment (est. wait: ${data['estimated_wait_minutes']} min)'),
            backgroundColor: Colors.teal,
          ),
        );
        _nameController.clear();
        return;
      }
    } catch (_) {
      // Fallback to local
    }

    // Local fallback
    setState(() {
      _myToken = _nextTokenCounter;
      _nextTokenCounter++;

      final deptQueue = _queueData.firstWhere(
        (q) => q['department'] == _selectedDepartment,
      );
      (deptQueue['waiting'] as List).add({
        'token': _myToken,
        'name': patientName,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token #$_myToken assigned for $_selectedDepartment'),
        backgroundColor: Colors.teal,
      ),
    );
    _nameController.clear();
  }

  void _callNextPatient(Map<String, dynamic> deptQueue) {
    setState(() {
      final waiting = deptQueue['waiting'] as List;
      if (waiting.isNotEmpty) {
        waiting.removeAt(0);
        deptQueue['currentlyServing'] = (deptQueue['currentlyServing'] as int) + 1;
      }
    });
  }

  int _getMyPosition() {
    if (_myToken == null) return 0;
    final deptQueue = _queueData.firstWhere(
      (q) => q['department'] == _selectedDepartment,
      orElse: () => _queueData.first,
    );
    final waiting = deptQueue['waiting'] as List;
    for (int i = 0; i < waiting.length; i++) {
      if (waiting[i]['token'] == _myToken) return i + 1;
    }
    return 0;
  }

  int _getCurrentServing() {
    final deptQueue = _queueData.firstWhere(
      (q) => q['department'] == _selectedDepartment,
      orElse: () => _queueData.first,
    );
    return deptQueue['currentlyServing'] as int;
  }

  int _getEstimatedWait() {
    final deptQueue = _queueData.firstWhere(
      (q) => q['department'] == _selectedDepartment,
      orElse: () => _queueData.first,
    );
    final avgTime = deptQueue['avgTime'] as int;
    final position = _getMyPosition();
    return position * avgTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('opd_queue'.tr()),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_myToken != null) _buildStatusBanner(),
          const SizedBox(height: 16),
          _buildCheckInSection(),
          const SizedBox(height: 20),
          _buildQueueBoard(),
          const SizedBox(height: 16),
          _buildWaitTimeInfo(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final position = _getMyPosition();
    final currentServing = _getCurrentServing();
    final estimatedWait = _getEstimatedWait();
    final totalInQueue = (position > 0) ? position : 1;

    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'YOUR QUEUE STATUS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Token #$_myToken',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Currently Serving: #$currentServing',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              position > 0
                  ? 'Estimated Wait: ~$estimatedWait minutes'
                  : 'You have been served or not in queue',
              style: TextStyle(
                fontSize: 16,
                color: position > 0 ? Colors.orange.shade800 : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (position > 0) ...[
              Row(
                children: [
                  Text('Position: $position ahead',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text('Dept: $_selectedDepartment',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalInQueue > 0
                      ? (1 - (position / (position + currentServing)))
                      : 1.0,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.teal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check-In for OPD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Patient Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: InputDecoration(
                labelText: 'Department',
                prefixIcon: const Icon(Icons.local_hospital),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDepartment = val!;
                  _selectedDoctor = 'Any Available';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDoctor,
              decoration: InputDecoration(
                labelText: 'Preferred Doctor (Optional)',
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: (doctorsByDept[_selectedDepartment] ?? ['Any Available'])
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedDoctor = val!);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _getToken,
                icon: const Icon(Icons.confirmation_number),
                label: const Text(
                  'Get Token',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueBoard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Live Queue Board',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        ..._queueData.map((dept) => _buildDeptQueueCard(dept)),
      ],
    );
  }

  Widget _buildDeptQueueCard(Map<String, dynamic> dept) {
    final waiting = dept['waiting'] as List;
    final currentServing = dept['currentlyServing'] as int;
    final avgTime = dept['avgTime'] as int;
    final nextToken = waiting.isNotEmpty ? waiting.first['token'] : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            '${waiting.length}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          dept['department'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Serving: #$currentServing  |  Next: #$nextToken  |  Avg: ${avgTime}min',
          style: const TextStyle(fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Waiting: ${waiting.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Avg Wait: ${waiting.length * avgTime} min',
                        style: TextStyle(color: Colors.orange.shade800)),
                  ],
                ),
                const Divider(),
                if (waiting.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No patients waiting',
                        style: TextStyle(color: Colors.green)),
                  )
                else
                  ...waiting.map((p) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.teal.shade100,
                          child: Text('#${p['token']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(p['name']),
                        trailing: Text(
                          'Wait: ~${(waiting.indexOf(p) + 1) * avgTime} min',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _callNextPatient(dept),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Call Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (waiting.isNotEmpty) {
                          setState(() => waiting.removeAt(0));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Patient marked complete')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Complete'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (waiting.isNotEmpty) {
                          setState(() {
                            final skipped = waiting.removeAt(0);
                            waiting.add(skipped);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Patient moved to end of queue')),
                          );
                        }
                      },
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitTimeInfo() {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Estimated wait = Avg consultation time per patient x Number of patients ahead of you in the queue.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
