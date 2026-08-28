import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../utils/api_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/patient/1'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          notifications = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int id) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
      );
      _fetchNotifications();
    } catch (_) {}
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'referral':
        return Icons.swap_horiz;
      case 'teleconsultation':
        return Icons.videocam;
      case 'diagnostic':
        return Icons.biotech;
      case 'queue':
        return Icons.confirmation_number;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'referral':
        return Colors.deepOrange;
      case 'teleconsultation':
        return Colors.blue;
      case 'diagnostic':
        return Colors.purple;
      case 'queue':
        return Colors.green;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('no_notifications'.tr(),
                          style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final isRead = notif['is_read'] == true;
                      return Card(
                        color: isRead ? null : Colors.teal.shade50,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(notif['type'] ?? '').withOpacity(0.1),
                            child: Icon(_getIcon(notif['type'] ?? ''),
                                color: _getColor(notif['type'] ?? '')),
                          ),
                          title: Text(notif['title'] ?? '',
                              style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif['message'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                notif['created_at']?.toString().substring(0, 16) ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.teal),
                                  onPressed: () => _markAsRead(notif['id']),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
