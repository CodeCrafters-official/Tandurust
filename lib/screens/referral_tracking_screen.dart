import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

enum ReferralStatus { pending, accepted, inTransit, completed, cancelled }

enum ReferralUrgency { routine, urgent, emergency }

class Referral {
  final String id;
  final String patientName;
  final String fromFacility;
  final String toFacility;
  final String reason;
  final ReferralUrgency urgency;
  final DateTime createdAt;
  ReferralStatus status;
  int? backendId;

  Referral({
    required this.id,
    required this.patientName,
    required this.fromFacility,
    required this.toFacility,
    required this.reason,
    required this.urgency,
    required this.createdAt,
    this.status = ReferralStatus.pending,
    this.backendId,
  });

  static ReferralStatus _parseStatus(String s) {
    switch (s) {
      case 'accepted': return ReferralStatus.accepted;
      case 'in_transit': return ReferralStatus.inTransit;
      case 'completed': return ReferralStatus.completed;
      case 'cancelled': return ReferralStatus.cancelled;
      default: return ReferralStatus.pending;
    }
  }

  static ReferralUrgency _parseUrgency(String s) {
    switch (s) {
      case 'urgent': return ReferralUrgency.urgent;
      case 'emergency': return ReferralUrgency.emergency;
      default: return ReferralUrgency.routine;
    }
  }

  static String statusToString(ReferralStatus s) {
    switch (s) {
      case ReferralStatus.accepted: return 'accepted';
      case ReferralStatus.inTransit: return 'in_transit';
      case ReferralStatus.completed: return 'completed';
      case ReferralStatus.cancelled: return 'cancelled';
      default: return 'pending';
    }
  }

  static String urgencyToString(ReferralUrgency u) {
    switch (u) {
      case ReferralUrgency.urgent: return 'urgent';
      case ReferralUrgency.emergency: return 'emergency';
      default: return 'routine';
    }
  }

  factory Referral.fromJson(Map<String, dynamic> json) {
    final fromFac = json['from_facility'];
    final toFac = json['to_facility'];
    final pat = json['patient'];
    return Referral(
      id: 'REF-${json['id'].toString().padLeft(3, '0')}',
      backendId: json['id'],
      patientName: pat != null ? pat['name'] ?? 'Unknown' : 'Unknown',
      fromFacility: fromFac != null ? fromFac['name'] ?? '' : '',
      toFacility: toFac != null ? toFac['name'] ?? '' : '',
      reason: json['reason'] ?? '',
      urgency: _parseUrgency(json['urgency'] ?? 'routine'),
      createdAt: json['referred_date'] != null
          ? DateTime.tryParse(json['referred_date']) ?? DateTime.now()
          : DateTime.now(),
      status: _parseStatus(json['status'] ?? 'pending'),
    );
  }
}

class ReferralTrackingScreen extends StatefulWidget {
  const ReferralTrackingScreen({super.key});

  @override
  State<ReferralTrackingScreen> createState() => _ReferralTrackingScreenState();
}

class _ReferralTrackingScreenState extends State<ReferralTrackingScreen> {
  bool _isLoading = true;

  List<String> facilities = [
    'Sub-Centre Wadgaon',
    'PHC Shirur',
    'CHC Baramati',
    'Rural Hospital Indapur',
    'District Hospital Pune',
    'Civil Hospital Satara',
  ];

  // Facility ID mapping for API calls
  List<Map<String, dynamic>> _facilityList = [];

  List<Referral> referrals = [];

  // Mock data fallback
  final List<Referral> _mockReferrals = [
    Referral(
      id: 'REF-001',
      patientName: 'Sunita Devi',
      fromFacility: 'PHC Shirur',
      toFacility: 'District Hospital Pune',
      reason: 'High-risk pregnancy requiring specialist consultation',
      urgency: ReferralUrgency.urgent,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: ReferralStatus.inTransit,
    ),
    Referral(
      id: 'REF-002',
      patientName: 'Ramesh Patil',
      fromFacility: 'Sub-Centre Wadgaon',
      toFacility: 'CHC Baramati',
      reason: 'Suspected cardiac issue — ECG required',
      urgency: ReferralUrgency.emergency,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: ReferralStatus.accepted,
    ),
    Referral(
      id: 'REF-003',
      patientName: 'Meena Jadhav',
      fromFacility: 'PHC Shirur',
      toFacility: 'Rural Hospital Indapur',
      reason: 'Chronic diabetes follow-up with endocrinologist',
      urgency: ReferralUrgency.routine,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ReferralStatus.completed,
    ),
    Referral(
      id: 'REF-004',
      patientName: 'Arjun Gaikwad',
      fromFacility: 'CHC Baramati',
      toFacility: 'District Hospital Pune',
      reason: 'Orthopedic surgery — fracture fixation',
      urgency: ReferralUrgency.urgent,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ReferralStatus.pending,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final facilitiesRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/facilities'),
      ).timeout(const Duration(seconds: 5));

      if (facilitiesRes.statusCode == 200) {
        final List<dynamic> facData = jsonDecode(facilitiesRes.body);
        _facilityList = facData.cast<Map<String, dynamic>>();
        facilities = _facilityList.map((f) => f['name'] as String).toList();
      }

      final referralsRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/referrals'),
      ).timeout(const Duration(seconds: 5));

      if (referralsRes.statusCode == 200) {
        final List<dynamic> refData = jsonDecode(referralsRes.body);
        referrals = refData.map((r) => Referral.fromJson(r)).toList();
      } else {
        referrals = List.from(_mockReferrals);
      }
    } catch (e) {
      referrals = List.from(_mockReferrals);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createReferralOnServer(String patientName, String from, String to, String reason, ReferralUrgency urgency) async {
    try {
      int? fromId = _facilityList.firstWhere((f) => f['name'] == from, orElse: () => {})['id'];
      int? toId = _facilityList.firstWhere((f) => f['name'] == to, orElse: () => {})['id'];

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/referrals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': 1,
          'from_facility_id': fromId ?? 1,
          'to_facility_id': toId ?? 2,
          'reason': reason,
          'urgency': Referral.urgencyToString(urgency),
          'notes': 'Created from app',
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> _updateStatusOnServer(Referral referral, ReferralStatus newStatus) async {
    if (referral.backendId == null) return;
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/referrals/${referral.backendId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': Referral.statusToString(newStatus)}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Color _statusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Colors.amber;
      case ReferralStatus.accepted:
        return Colors.blue;
      case ReferralStatus.inTransit:
        return Colors.orange;
      case ReferralStatus.completed:
        return Colors.green;
      case ReferralStatus.cancelled:
        return Colors.grey;
    }
  }

  String _statusLabel(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return 'Pending';
      case ReferralStatus.accepted:
        return 'Accepted';
      case ReferralStatus.inTransit:
        return 'In Transit';
      case ReferralStatus.completed:
        return 'Completed';
      case ReferralStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _statusIcon(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Icons.hourglass_empty;
      case ReferralStatus.accepted:
        return Icons.check_circle_outline;
      case ReferralStatus.inTransit:
        return Icons.directions_car;
      case ReferralStatus.completed:
        return Icons.done_all;
      case ReferralStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _urgencyColor(ReferralUrgency urgency) {
    switch (urgency) {
      case ReferralUrgency.routine:
        return Colors.green;
      case ReferralUrgency.urgent:
        return Colors.orange;
      case ReferralUrgency.emergency:
        return Colors.red;
    }
  }

  String _urgencyLabel(ReferralUrgency urgency) {
    switch (urgency) {
      case ReferralUrgency.routine:
        return 'Routine';
      case ReferralUrgency.urgent:
        return 'Urgent';
      case ReferralUrgency.emergency:
        return 'Emergency';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showCreateReferralSheet() {
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String? fromFacility;
    String? toFacility;
    ReferralUrgency urgency = ReferralUrgency.routine;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.send, color: Colors.teal),
                        const SizedBox(width: 10),
                        const Text(
                          'Create Referral',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Patient Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: fromFacility,
                      decoration: InputDecoration(
                        labelText: 'From Facility',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: facilities
                          .map((f) =>
                              DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => fromFacility = v),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: toFacility,
                      decoration: InputDecoration(
                        labelText: 'To Facility',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: facilities
                          .map((f) =>
                              DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => toFacility = v),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Reason for Referral',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<ReferralUrgency>(
                      value: urgency,
                      decoration: InputDecoration(
                        labelText: 'Urgency',
                        prefixIcon: const Icon(Icons.priority_high),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ReferralUrgency.values
                          .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(_urgencyLabel(u))))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => urgency = v!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Referral',
                            style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          if (nameCtrl.text.isEmpty ||
                              fromFacility == null ||
                              toFacility == null ||
                              reasonCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please fill all fields')),
                            );
                            return;
                          }
                          _createReferralOnServer(nameCtrl.text, fromFacility!, toFacility!, reasonCtrl.text, urgency);
                          setState(() {
                            referrals.insert(
                              0,
                              Referral(
                                id: 'REF-${(referrals.length + 1).toString().padLeft(3, '0')}',
                                patientName: nameCtrl.text,
                                fromFacility: fromFacility!,
                                toFacility: toFacility!,
                                reason: reasonCtrl.text,
                                urgency: urgency,
                                createdAt: DateTime.now(),
                              ),
                            );
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral created successfully'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReferralDetails(Referral referral) {
    final allStatuses = ReferralStatus.values
        .where((s) => s != ReferralStatus.cancelled)
        .toList();
    final currentIndex = allStatuses.indexOf(referral.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _statusColor(referral.status),
                    child: Icon(_statusIcon(referral.status),
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(referral.patientName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(referral.id,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _urgencyColor(referral.urgency)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _urgencyColor(referral.urgency)),
                    ),
                    child: Text(
                      _urgencyLabel(referral.urgency),
                      style: TextStyle(
                        color: _urgencyColor(referral.urgency),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.location_on_outlined, 'From',
                  referral.fromFacility),
              _detailRow(
                  Icons.location_on, 'To', referral.toFacility),
              _detailRow(Icons.note, 'Reason', referral.reason),
              _detailRow(Icons.access_time, 'Created',
                  _formatDate(referral.createdAt)),
              const SizedBox(height: 20),
              const Text('Referral Progress',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTimeline(allStatuses, currentIndex, referral),
              const SizedBox(height: 20),
              if (referral.status != ReferralStatus.completed &&
                  referral.status != ReferralStatus.cancelled)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Advance Status'),
                        onPressed: () {
                          final nextIndex = currentIndex + 1;
                          if (nextIndex < allStatuses.length) {
                            final newStatus = allStatuses[nextIndex];
                            _updateStatusOnServer(referral, newStatus);
                            setState(() {
                              referral.status = newStatus;
                            });
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      onPressed: () {
                        _updateStatusOnServer(referral, ReferralStatus.cancelled);
                        setState(() {
                          referral.status = ReferralStatus.cancelled;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text('$label:',
                style: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child:
                  Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildTimeline(
      List<ReferralStatus> statuses, int currentIndex, Referral ref) {
    return Row(
      children: List.generate(statuses.length, (i) {
        final isActive = i <= currentIndex;
        final isCurrent = i == currentIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i <= currentIndex
                            ? _statusColor(statuses[i])
                            : Colors.grey[300],
                      ),
                    ),
                  CircleAvatar(
                    radius: isCurrent ? 16 : 12,
                    backgroundColor: isActive
                        ? _statusColor(statuses[i])
                        : Colors.grey[300],
                    child: Icon(
                      _statusIcon(statuses[i]),
                      size: isCurrent ? 16 : 12,
                      color: Colors.white,
                    ),
                  ),
                  if (i < statuses.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < currentIndex
                            ? _statusColor(statuses[i + 1])
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _statusLabel(statuses[i]),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('referral_tracking'.tr()),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReferralSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('New Referral'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : referrals.isEmpty
          ? const Center(
              child: Text('No referrals yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: referrals.length,
              itemBuilder: (context, index) {
                final ref = referrals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showReferralDetails(ref),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    _statusColor(ref.status)
                                        .withOpacity(0.2),
                                child: Icon(
                                  _statusIcon(ref.status),
                                  color: _statusColor(ref.status),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(ref.patientName,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ref.fromFacility} → ${ref.toFacility}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _urgencyColor(
                                              ref.urgency)
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _urgencyLabel(ref.urgency),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _urgencyColor(
                                            ref.urgency),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(ref.createdAt),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(ref.reason,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _statusColor(ref.status)
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(ref.status),
                                    size: 14,
                                    color:
                                        _statusColor(ref.status)),
                                const SizedBox(width: 6),
                                Text(
                                  _statusLabel(ref.status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _statusColor(ref.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
