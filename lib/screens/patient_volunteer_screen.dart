// lib/screens/patient_volunteer_screen.dart
import 'package:flutter/material.dart';

class PatientVolunteerScreen extends StatefulWidget {
  const PatientVolunteerScreen({super.key});

  @override
  State<PatientVolunteerScreen> createState() => _PatientVolunteerScreenState();
}

class _PatientVolunteerScreenState extends State<PatientVolunteerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for volunteer tasks
  final List<Map<String, dynamic>> volunteerTasks = [
    {
      'requester': 'Pavithra',
      'task': 'Pick up medicine from pharmacy',
      'points': 10,
      'status': 'pending',
    },
    {
      'requester': 'Priyadharshini',
      'task': 'Take elderly to hospital appointment',
      'points': 20,
      'status': 'pending',
    },
    {
      'requester': 'Kausika',
      'task': 'Buy glucose meter for diabetic patient',
      'points': 15,
      'status': 'pending',
    },
    {
      'requester': 'Mohamed Arsath',
      'task': 'Deliver medical supplies to nearby clinic',
      'points': 12,
      'status': 'pending',
    },
    {
      'requester': 'Lakshmi Pradeepa',
      'task': 'Help with hospital paperwork',
      'points': 8,
      'status': 'pending',
    },
  ];

  // Mock data for my help requests
  final List<Map<String, String>> myRequests = [
    {
      'task': 'Need someone to deliver insulin',
      'status': 'open',
    },
    {
      'task': 'Looking for blood donor for a friend',
      'status': 'in progress',
    },
    {
      'task': 'Need help with hospital appointment booking',
      'status': 'completed',
    },
  ];

  // Mock leaderboard
  final List<Map<String, dynamic>> leaderboard = [
    {'name': 'Pavithra', 'points': 120},
    {'name': 'Priyadharshini', 'points': 100},
    {'name': 'You', 'points': 50}, // current user
    {'name': 'Kausika', 'points': 40},
    {'name': 'Mohamed Arsath', 'points': 30},
    {'name': 'Lakshmi Pradeepa', 'points': 30},
  ];

  int myPoints = 50; // initial mock points

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void acceptTask(int index) {
    setState(() {
      volunteerTasks[index]['status'] = 'accepted';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You accepted: ${volunteerTasks[index]['task']}')),
    );
  }

  void completeTask(int index) {
    setState(() {
      volunteerTasks[index]['status'] = 'completed';
      myPoints += volunteerTasks[index]['points'] as int;
      leaderboard[2]['points'] = myPoints; // update current user points
      leaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Task completed! You earned ${volunteerTasks[index]['points']} points')),
    );
  }

  void addHelpRequest(String task) {
    setState(() {
      myRequests.add({'task': task, 'status': 'open'});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help request added')),
    );
  }

  void showLeaderboard() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leaderboard'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final user = leaderboard[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(user['name']),
                trailing: Text('${user['points']} pts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: user['name'] == 'You' ? Colors.teal : Colors.black)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _requestController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Help'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Volunteer Tasks'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Volunteer Tasks tab
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: volunteerTasks.length,
            itemBuilder: (context, index) {
              final task = volunteerTasks[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(task['task']),
                  subtitle: Text('Requested by: ${task['requester']}'),
                  trailing: task['status'] == 'pending'
                      ? ElevatedButton(
                    onPressed: () => acceptTask(index),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Accept'),
                  )
                      : task['status'] == 'accepted'
                      ? ElevatedButton(
                    onPressed: () => completeTask(index),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text('Complete'),
                  )
                      : const Icon(Icons.check_circle, color: Colors.grey),
                ),
              );
            },
          ),

          // My Requests tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _requestController,
                        decoration: const InputDecoration(
                          hintText: 'Add a help request',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_requestController.text.trim().isNotEmpty) {
                          addHelpRequest(_requestController.text.trim());
                          _requestController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text('Add'),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: myRequests.length,
                  itemBuilder: (context, index) {
                    final request = myRequests[index];
                    String status = request['status'] ?? 'open';
                    Color statusColor;
                    switch (request['status']) {
                      case 'open':
                        statusColor = Colors.orange;
                        break;
                      case 'in progress':
                        statusColor = Colors.blue;
                        break;
                      case 'completed':
                        statusColor = Colors.green;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(request['task'] ?? ''),
                        trailing: Text(
                          (request['status'] ?? 'open').toUpperCase(),
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showLeaderboard,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.leaderboard),
        label: Text('Points: $myPoints'),
      ),
    );
  }
}
