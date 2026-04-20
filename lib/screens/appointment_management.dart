import 'package:flutter/material.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  // Updated mock appointment data
  List<Map<String, dynamic>> appointments = [
    {'patient': 'Pavithra', 'time': '10:00 AM', 'status': 'Pending'},
    {'patient': 'Priyadharshini', 'time': '11:30 AM', 'status': 'Pending'},
    {'patient': 'Kausika', 'time': '02:00 PM', 'status': 'Accepted'},
    {'patient': 'Arsath', 'time': '02:30 PM', 'status': 'Pending'},
    {'patient': 'Pradeepa', 'time': '03:30 PM', 'status': 'Pending'},
  ];

  void _updateStatus(int index, String status) {
    setState(() {
      appointments[index]['status'] = status;
    });
  }

  void _rescheduleAppointment(int index) async {
    // Convert current time string to TimeOfDay
    final parts = appointments[index]['time'].split(RegExp(r'[: ]'));
    int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final String amPm = parts[2];
    if (amPm.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (amPm.toUpperCase() == 'AM' && hour == 12) hour = 0;

    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (newTime != null) {
      setState(() {
        appointments[index]['time'] = newTime.format(context);
        appointments[index]['status'] = 'Rescheduled';
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rescheduled':
        return Colors.blue;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Management"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final statusColor = _getStatusColor(appointment['status']);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.person, color: statusColor),
              title: Text(appointment['patient']),
              subtitle: Text(appointment['time']),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: statusColor),
                onSelected: (value) {
                  if (value == 'Accept') {
                    _updateStatus(index, 'Accepted');
                  } else if (value == 'Complete') {
                    _updateStatus(index, 'Completed');
                  } else if (value == 'Reschedule') {
                    _rescheduleAppointment(index);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Accept',
                    child: Text('Accept'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Reschedule',
                    child: Text('Reschedule'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Complete',
                    child: Text('Completed'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
