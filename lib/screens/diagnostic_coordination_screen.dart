import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

enum TestStatus { ordered, sampleCollected, processing, completed }

class LabOrder {
  final String patientName;
  final String testType;
  final String urgency;
  final String facility;
  final String orderedBy;
  final String date;
  final String? notes;
  TestStatus status;
  String? resultSummary;
  bool hasAbnormal;

  LabOrder({
    required this.patientName,
    required this.testType,
    required this.urgency,
    required this.facility,
    required this.orderedBy,
    required this.date,
    this.notes,
    this.status = TestStatus.ordered,
    this.resultSummary,
    this.hasAbnormal = false,
  });
}

class DiagnosticCoordinationScreen extends StatefulWidget {
  const DiagnosticCoordinationScreen({super.key});

  @override
  State<DiagnosticCoordinationScreen> createState() =>
      _DiagnosticCoordinationScreenState();
}

class _DiagnosticCoordinationScreenState
    extends State<DiagnosticCoordinationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _patientNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedTest = 'Blood Test - CBC';
  String _selectedUrgency = 'Routine';
  String _selectedFacility = 'PHC Lab - Latur';
  bool _showOrderForm = false;

  final List<String> _testTypes = [
    'Blood Test - CBC',
    'Blood Sugar',
    'Thyroid Panel',
    'Lipid Profile',
    'Urine Analysis',
    'X-Ray',
    'ECG',
    'Ultrasound',
    'Malaria RDT',
    'HIV Test',
  ];

  final List<String> _facilities = [
    'PHC Lab - Latur',
    'CHC Lab - Osmanabad',
    'District Hospital Lab - Solapur',
    'Private Diagnostic Centre - MedScan',
  ];

  List<LabOrder> orders = [
    LabOrder(
      patientName: 'Ramesh Jadhav',
      testType: 'Blood Test - CBC',
      urgency: 'Urgent',
      facility: 'PHC Lab - Latur',
      orderedBy: 'Dr. Ananya Sharma',
      date: '2026-08-25',
      status: TestStatus.ordered,
    ),
    LabOrder(
      patientName: 'Sunita Deshmukh',
      testType: 'Thyroid Panel',
      urgency: 'Routine',
      facility: 'CHC Lab - Osmanabad',
      orderedBy: 'Dr. Rohan Mehta',
      date: '2026-08-24',
      status: TestStatus.sampleCollected,
    ),
    LabOrder(
      patientName: 'Akash Patil',
      testType: 'Malaria RDT',
      urgency: 'Urgent',
      facility: 'PHC Lab - Latur',
      orderedBy: 'Dr. Sneha Iyer',
      date: '2026-08-23',
      status: TestStatus.processing,
    ),
    LabOrder(
      patientName: 'Meena Gaikwad',
      testType: 'Blood Sugar',
      urgency: 'Routine',
      facility: 'District Hospital Lab - Solapur',
      orderedBy: 'Dr. Aditya Rao',
      date: '2026-08-20',
      status: TestStatus.completed,
      resultSummary: 'Fasting: 142 mg/dL (High), PP: 210 mg/dL (High)',
      hasAbnormal: true,
    ),
    LabOrder(
      patientName: 'Vijay Kulkarni',
      testType: 'Lipid Profile',
      urgency: 'Routine',
      facility: 'CHC Lab - Osmanabad',
      orderedBy: 'Dr. Ananya Sharma',
      date: '2026-08-19',
      status: TestStatus.completed,
      resultSummary:
          'Total Cholesterol: 195 mg/dL, LDL: 120 mg/dL, HDL: 48 mg/dL, Triglycerides: 155 mg/dL',
      hasAbnormal: false,
    ),
    LabOrder(
      patientName: 'Priya Shinde',
      testType: 'Urine Analysis',
      urgency: 'Routine',
      facility: 'PHC Lab - Latur',
      orderedBy: 'Dr. Sneha Iyer',
      date: '2026-08-18',
      status: TestStatus.completed,
      resultSummary: 'Protein: Trace (Abnormal), Glucose: Negative, WBC: 2-4/hpf',
      hasAbnormal: true,
    ),
    LabOrder(
      patientName: 'Ganesh More',
      testType: 'ECG',
      urgency: 'Urgent',
      facility: 'District Hospital Lab - Solapur',
      orderedBy: 'Dr. Rohan Mehta',
      date: '2026-08-17',
      status: TestStatus.completed,
      resultSummary: 'Normal sinus rhythm. No ST-segment abnormalities.',
      hasAbnormal: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDiagnostics();
  }

  Future<void> _fetchDiagnostics() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/diagnostics'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            orders = data.map<LabOrder>((d) {
              TestStatus status;
              switch (d['status'] ?? 'ordered') {
                case 'sample_collected':
                  status = TestStatus.sampleCollected;
                  break;
                case 'processing':
                  status = TestStatus.processing;
                  break;
                case 'completed':
                  status = TestStatus.completed;
                  break;
                default:
                  status = TestStatus.ordered;
              }
              return LabOrder(
                patientName: d['patient_name'] ?? 'Unknown',
                testType: d['test_name'] ?? 'Unknown Test',
                urgency: d['urgency'] ?? 'Routine',
                facility: d['facility_name'] ?? 'Unknown Facility',
                orderedBy: d['ordered_by'] ?? 'Doctor',
                date: d['ordered_date'] ?? '',
                status: status,
                resultSummary: d['result'],
                hasAbnormal: (d['result'] ?? '').toString().toLowerCase().contains('high') ||
                    (d['result'] ?? '').toString().toLowerCase().contains('abnormal'),
                notes: d['notes'],
              );
            }).toList();
          });
        }
      }
    } catch (_) {
      // Use mock data as fallback
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<LabOrder> get _activeOrders =>
      orders.where((o) => o.status != TestStatus.completed).toList();

  List<LabOrder> get _completedOrders =>
      orders.where((o) => o.status == TestStatus.completed).toList();

  void _submitOrder() async {
    if (_patientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient name')),
      );
      return;
    }

    final patientName = _patientNameCtrl.text.trim();
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    // Add locally immediately
    setState(() {
      orders.insert(
        0,
        LabOrder(
          patientName: patientName,
          testType: _selectedTest,
          urgency: _selectedUrgency,
          facility: _selectedFacility,
          orderedBy: 'Dr. Ananya Sharma',
          date: '2026-08-27',
          notes: notes,
          status: TestStatus.ordered,
        ),
      );
      _patientNameCtrl.clear();
      _notesCtrl.clear();
      _showOrderForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test ordered successfully'),
        backgroundColor: Colors.teal,
      ),
    );

    // POST to backend
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/diagnostics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': 1,
          'facility_id': 1,
          'test_name': _selectedTest,
          'ordered_by': 'Dr. Ananya Sharma',
          'urgency': _selectedUrgency.toLowerCase(),
          'notes': notes,
        }),
      );
    } catch (_) {
      // Backend sync failed silently, local state already updated
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('lab_diagnostics'.tr()),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'Completed (${_completedOrders.length})'),
            Tab(text: 'All (${orders.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showOrderForm = !_showOrderForm),
        backgroundColor: Colors.teal,
        icon: Icon(_showOrderForm ? Icons.close : Icons.add),
        label: Text(_showOrderForm ? 'Cancel' : 'Order Test'),
      ),
      body: Column(
        children: [
          if (_showOrderForm) _buildOrderForm(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_activeOrders, showProgress: true),
                _buildOrderList(_completedOrders, showProgress: false),
                _buildOrderList(orders, showProgress: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderForm() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order New Test',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _patientNameCtrl,
            decoration: InputDecoration(
              labelText: 'Patient Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTest,
            decoration: InputDecoration(
              labelText: 'Test Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.biotech),
            ),
            items: _testTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedTest = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUrgency,
                  decoration: InputDecoration(
                    labelText: 'Urgency',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['Routine', 'Urgent']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUrgency = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFacility,
                  decoration: InputDecoration(
                    labelText: 'Facility',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _facilities
                      .map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFacility = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(Icons.send),
              label: const Text('Order Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<LabOrder> list, {required bool showProgress}) {
    if (list.isEmpty) {
      return const Center(child: Text('No orders found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        return _buildOrderCard(order, showProgress: showProgress);
      },
    );
  }

  Widget _buildOrderCard(LabOrder order, {required bool showProgress}) {
    final isCompleted = order.status == TestStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: order.urgency == 'Urgent'
                      ? Colors.red.shade100
                      : Colors.teal.shade100,
                  child: Icon(
                    _testIcon(order.testType),
                    color: order.urgency == 'Urgent' ? Colors.red : Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.testType,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order.patientName,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                if (order.urgency == 'Urgent')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(order.orderedBy, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(order.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_hospital, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(order.facility, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            if (showProgress && !isCompleted) ...[
              const SizedBox(height: 14),
              _buildStatusPipeline(order.status),
            ],
            if (isCompleted && order.resultSummary != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.hasAbnormal ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: order.hasAbnormal ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          order.hasAbnormal ? Icons.warning_amber : Icons.check_circle,
                          size: 16,
                          color: order.hasAbnormal ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.hasAbnormal ? 'Abnormal Values Detected' : 'All Values Normal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: order.hasAbnormal ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.resultSummary!,
                      style: TextStyle(
                        fontSize: 13,
                        color: order.hasAbnormal ? Colors.red.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showFullReport(order);
                        },
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('View Full Report'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPipeline(TestStatus status) {
    final stages = [
      'Ordered',
      'Sample Collected',
      'Processing',
      'Completed',
    ];
    final currentIndex = status.index;

    return Row(
      children: List.generate(stages.length, (i) {
        final isActive = i <= currentIndex;
        final isLast = i == stages.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.teal : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: isActive
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stages[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? Colors.teal : Colors.grey,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentIndex ? Colors.teal : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showFullReport(LabOrder order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${order.testType} Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _reportRow('Patient', order.patientName),
              _reportRow('Test', order.testType),
              _reportRow('Date', order.date),
              _reportRow('Facility', order.facility),
              _reportRow('Ordered By', order.orderedBy),
              const Divider(),
              const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                order.resultSummary ?? 'No results available',
                style: TextStyle(
                  color: order.hasAbnormal ? Colors.red.shade700 : Colors.black87,
                ),
              ),
              if (order.hasAbnormal) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Abnormal values detected. Please consult the referring doctor.',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  IconData _testIcon(String testType) {
    if (testType.contains('Blood') || testType.contains('CBC')) return Icons.bloodtype;
    if (testType.contains('X-Ray') || testType.contains('Ultrasound')) return Icons.image;
    if (testType.contains('ECG')) return Icons.monitor_heart;
    if (testType.contains('Urine')) return Icons.science;
    if (testType.contains('Malaria') || testType.contains('HIV')) return Icons.coronavirus;
    return Icons.biotech;
  }
}
