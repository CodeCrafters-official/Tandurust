import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class TeleconsultationScreen extends StatefulWidget {
  const TeleconsultationScreen({super.key});

  @override
  State<TeleconsultationScreen> createState() => _TeleconsultationScreenState();
}

class _TeleconsultationScreenState extends State<TeleconsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> availableDoctors = [
    {'name': 'Dr. Meena Sharma', 'specialty': 'Cardiologist', 'online': true, 'experience': 12},
    {'name': 'Dr. Rajesh Gupta', 'specialty': 'Neurologist', 'online': true, 'experience': 15},
    {'name': 'Dr. Priya Nair', 'specialty': 'Gynecologist', 'online': false, 'experience': 9},
    {'name': 'Dr. Suresh Patel', 'specialty': 'Pediatrician', 'online': true, 'experience': 7},
    {'name': 'Dr. Kavita Deshmukh', 'specialty': 'Orthopedic', 'online': false, 'experience': 11},
    {'name': 'Dr. Anil Joshi', 'specialty': 'Dermatologist', 'online': true, 'experience': 6},
  ];

  final List<Map<String, dynamic>> scheduledConsultations = [
    {
      'doctor': 'Dr. Meena Sharma',
      'specialty': 'Cardiologist',
      'patient': 'Ramesh Kumar',
      'date': '2026-08-28',
      'time': '10:00 AM',
      'mode': 'Video',
      'status': 'Scheduled',
    },
    {
      'doctor': 'Dr. Rajesh Gupta',
      'specialty': 'Neurologist',
      'patient': 'Sunita Devi',
      'date': '2026-08-28',
      'time': '11:30 AM',
      'mode': 'Audio',
      'status': 'Scheduled',
    },
    {
      'doctor': 'Dr. Suresh Patel',
      'specialty': 'Pediatrician',
      'patient': 'Baby Arjun',
      'date': '2026-08-27',
      'time': '03:00 PM',
      'mode': 'Video',
      'status': 'In Progress',
    },
  ];

  final List<Map<String, dynamic>> pastConsultations = [
    {
      'doctor': 'Dr. Priya Nair',
      'specialty': 'Gynecologist',
      'patient': 'Lakshmi Bai',
      'date': '2026-08-25',
      'mode': 'Video',
      'notes': 'Routine prenatal checkup. All vitals normal. Next visit in 2 weeks.',
      'prescription': 'Folic acid 5mg, Iron supplement',
    },
    {
      'doctor': 'Dr. Meena Sharma',
      'specialty': 'Cardiologist',
      'patient': 'Ramesh Kumar',
      'date': '2026-08-20',
      'mode': 'Audio',
      'notes': 'BP elevated. Advised lifestyle changes and medication adjustment.',
      'prescription': 'Amlodipine 5mg, Aspirin 75mg',
    },
    {
      'doctor': 'Dr. Rajesh Gupta',
      'specialty': 'Neurologist',
      'patient': 'Sunita Devi',
      'date': '2026-08-18',
      'mode': 'Chat',
      'notes': 'Persistent headaches. Referred for MRI at district hospital.',
      'prescription': 'Sumatriptan 50mg as needed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTeleconsultations();
  }

  Future<void> _fetchTeleconsultations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/teleconsultations'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            scheduledConsultations.clear();
            pastConsultations.clear();
            for (var item in data) {
              final map = {
                'id': item['id'],
                'doctor': item['doctor_name'] ?? 'Unknown',
                'specialty': item['specialty'] ?? '',
                'patient': item['patient_name'] ?? 'Patient',
                'date': item['scheduled_time']?.toString().split('T')[0] ?? '',
                'time': item['scheduled_time']?.toString().split('T').last.substring(0, 5) ?? '',
                'mode': item['call_type'] == 'audio' ? 'Audio' : 'Video',
                'status': item['status'] ?? 'scheduled',
                'notes': item['notes'] ?? '',
                'prescription': item['prescription'] ?? '',
              };
              if (map['status'] == 'completed') {
                pastConsultations.add(map);
              } else {
                scheduledConsultations.add(map);
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _scheduleConsultation(Map<String, dynamic> doctor, String mode) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/teleconsultations'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "patient_id": 1,
          "doctor_name": doctor['name'],
          "scheduled_time": DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          "call_type": mode.toLowerCase(),
          "notes": "",
        }),
      );
      _fetchTeleconsultations();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('teleconsultation'.tr()),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.people), text: 'doctors'.tr()),
            Tab(icon: const Icon(Icons.schedule), text: 'upcoming'.tr()),
            Tab(icon: const Icon(Icons.history), text: 'history'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoctorsTab(),
          _buildScheduledTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // =================== DOCTORS TAB ===================

  Widget _buildDoctorsTab() {
    final online = availableDoctors.where((d) => d['online'] == true).toList();
    final offline = availableDoctors.where((d) => d['online'] == false).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('connect_with_specialists'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('consult_remotely'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('online_now'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 12),
        ...online.map((d) => _buildDoctorCard(d)),

        const SizedBox(height: 20),
        Text('offline'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        ...offline.map((d) => _buildDoctorCard(d)),
      ],
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final isOnline = doctor['online'] as bool;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, size: 30, color: Colors.teal.shade700),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(doctor['specialty'], style: TextStyle(color: Colors.grey.shade600)),
                  Text("${doctor['experience']} yrs experience", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: isOnline ? () => _startConsultation(doctor, 'Video') : null,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text('video'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: isOnline ? () => _startConsultation(doctor, 'Audio') : null,
                  icon: const Icon(Icons.phone, size: 16),
                  label: Text('audio'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =================== SCHEDULED TAB ===================

  Widget _buildScheduledTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...scheduledConsultations.map((c) => _buildScheduledCard(c)),
        if (scheduledConsultations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('no_upcoming'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduledCard(Map<String, dynamic> consultation) {
    final status = consultation['status'] as String;
    final isJoinable = status == 'Scheduled' || status == 'In Progress';
    Color statusColor;
    switch (status) {
      case 'In Progress':
        statusColor = Colors.green;
        break;
      case 'Scheduled':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  consultation['mode'] == 'Video' ? Icons.videocam : Icons.phone,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(consultation['doctor'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(consultation['specialty'], style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text("Patient: ${consultation['patient']}", style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text("${consultation['date']} at ${consultation['time']}", style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(consultation['mode'], style: const TextStyle(fontSize: 12)),
                  avatar: Icon(
                    consultation['mode'] == 'Video' ? Icons.videocam : Icons.phone,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                if (isJoinable)
                  ElevatedButton.icon(
                    onPressed: () => _joinConsultation(consultation),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(status == 'In Progress' ? 'rejoin'.tr() : 'join'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'In Progress' ? Colors.green : Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =================== HISTORY TAB ===================

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...pastConsultations.map((c) => _buildHistoryCard(c)),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> consultation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(Icons.check_circle, color: Colors.teal.shade700),
        ),
        title: Text(consultation['doctor'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${consultation['date']} - ${consultation['mode']}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text("Patient: ${consultation['patient']}"),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(consultation['notes'] ?? 'No notes'),
                const SizedBox(height: 12),
                const Text("Prescription:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(consultation['prescription'] ?? 'No prescription'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== ACTIONS ===================

  void _startConsultation(Map<String, dynamic> doctor, String mode) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/teleconsultations'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "patient_id": 1,
          "doctor_name": doctor['name'],
          "scheduled_time": DateTime.now().toIso8601String().substring(0, 16),
          "call_type": mode.toLowerCase(),
        }),
      );
      String roomId = '';
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        roomId = data['teleconsultation']['room_id'] ?? '';
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ConsultationRoomScreen(
            doctorName: doctor['name'],
            specialty: doctor['specialty'],
            mode: mode,
            roomId: roomId,
          ),
        ),
      );
      _fetchTeleconsultations();
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ConsultationRoomScreen(
            doctorName: doctor['name'],
            specialty: doctor['specialty'],
            mode: mode,
            roomId: 'tandurust-${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    }
  }

  void _joinConsultation(Map<String, dynamic> consultation) async {
    String roomId = '';
    if (consultation['id'] != null) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/teleconsultations/${consultation['id']}/join'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          roomId = data['room_id'] ?? '';
        }
      } catch (_) {}
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ConsultationRoomScreen(
          doctorName: consultation['doctor'],
          specialty: consultation['specialty'],
          mode: consultation['mode'],
          roomId: roomId,
        ),
      ),
    );
  }
}

// =================== CONSULTATION ROOM ===================

class _ConsultationRoomScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String mode;
  final String roomId;

  const _ConsultationRoomScreen({
    required this.doctorName,
    required this.specialty,
    required this.mode,
    this.roomId = '',
  });

  @override
  State<_ConsultationRoomScreen> createState() => _ConsultationRoomScreenState();
}

class _ConsultationRoomScreenState extends State<_ConsultationRoomScreen> {
  bool isMuted = false;
  bool isVideoOn = true;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> chatMessages = [
    {'sender': 'system', 'message': 'Consultation started. Connecting...'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text("${widget.mode} Consultation"),
        backgroundColor: Colors.teal.shade800,
        actions: [
          TextButton.icon(
            onPressed: _addPrescription,
            icon: const Icon(Icons.medication, color: Colors.white),
            label: Text('prescribe'.tr(), style: const TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: _referPatient,
            icon: const Icon(Icons.swap_horiz, color: Colors.orange),
            label: Text('refer'.tr(), style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.black87,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.mode == 'Video' ? Icons.videocam : Icons.phone_in_talk,
                        size: 80,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      Text(widget.doctorName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(widget.specialty, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("Connected", style: TextStyle(color: Colors.greenAccent)),
                      ),
                      if (widget.roomId.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openJitsiCall,
                          icon: const Icon(Icons.open_in_new),
                          label: Text('open_video_call'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Room: ${widget.roomId}",
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                // Self view (small)
                if (widget.mode == 'Video')
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 100,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white54, size: 40),
                      ),
                    ),
                  ),
                // Duration
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text("05:23", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat / Notes section
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.teal,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'chat'.tr()),
                        Tab(text: 'notes'.tr()),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildChatSection(),
                          _buildNotesSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls bar
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  icon: isMuted ? Icons.mic_off : Icons.mic,
                  label: isMuted ? 'unmute'.tr() : 'mute'.tr(),
                  color: isMuted ? Colors.red : Colors.white,
                  onTap: () => setState(() => isMuted = !isMuted),
                ),
                if (widget.mode == 'Video')
                  _controlButton(
                    icon: isVideoOn ? Icons.videocam : Icons.videocam_off,
                    label: isVideoOn ? 'video_on'.tr() : 'video_off'.tr(),
                    color: isVideoOn ? Colors.white : Colors.red,
                    onTap: () => setState(() => isVideoOn = !isVideoOn),
                  ),
                _controlButton(
                  icon: Icons.screen_share,
                  label: 'share'.tr(),
                  color: Colors.white,
                  onTap: () {},
                ),
                _controlButton(
                  icon: Icons.call_end,
                  label: 'end'.tr(),
                  color: Colors.red,
                  bgColor: Colors.red,
                  onTap: () => _endConsultation(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor?.withOpacity(0.2) ?? Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              final msg = chatMessages[index];
              final isSystem = msg['sender'] == 'system';
              return Align(
                alignment: isSystem ? Alignment.center : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSystem ? Colors.grey.shade300 : Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg['message']!, style: TextStyle(fontSize: 13, color: isSystem ? Colors.grey.shade700 : Colors.black87)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_chatController.text.isNotEmpty) {
                    setState(() {
                      chatMessages.add({'sender': 'me', 'message': _chatController.text});
                      _chatController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.send, color: Colors.teal),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _notesController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: "Add consultation notes here...",
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  void _openJitsiCall() async {
    final url = Uri.parse('https://meet.jit.si/${widget.roomId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _addPrescription() {
    showDialog(
      context: context,
      builder: (_) {
        final medCtrl = TextEditingController();
        final doseCtrl = TextEditingController();
        return AlertDialog(
          title: Text('add_prescription'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: medCtrl, decoration: const InputDecoration(labelText: "Medicine")),
              TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: "Dosage & Duration")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  chatMessages.add({
                    'sender': 'system',
                    'message': 'Prescription added: ${medCtrl.text} - ${doseCtrl.text}'
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _referPatient() {
    showDialog(
      context: context,
      builder: (_) {
        String selectedFacility = 'District Hospital';
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          title: Text('refer_patient'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedFacility,
                items: const [
                  DropdownMenuItem(value: 'District Hospital', child: Text('District Hospital')),
                  DropdownMenuItem(value: 'Sub-District Hospital', child: Text('Sub-District Hospital')),
                  DropdownMenuItem(value: 'Specialist Centre', child: Text('Specialist Centre')),
                  DropdownMenuItem(value: 'Medical College', child: Text('Medical College Hospital')),
                ],
                onChanged: (v) => selectedFacility = v!,
                decoration: const InputDecoration(labelText: "Refer to"),
              ),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Reason for referral")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  chatMessages.add({
                    'sender': 'system',
                    'message': 'Referral created to $selectedFacility: ${reasonCtrl.text}'
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Patient referred to $selectedFacility")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Refer"),
            ),
          ],
        );
      },
    );
  }

  void _endConsultation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('end_consultation'.tr()),
        content: Text('end_consultation_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('consultation_ended'.tr())),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("End"),
          ),
        ],
      ),
    );
  }
}
