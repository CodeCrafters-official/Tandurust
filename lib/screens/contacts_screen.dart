import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  // Mock patient data
  final List<Map<String, String>> _patients = [
    {'name': 'John Doe', 'age': '30', 'condition': 'Fever'},
    {'name': 'Jane Smith', 'age': '25', 'condition': 'Headache'},
    {'name': 'Robert Brown', 'age': '45', 'condition': 'Diabetes'},
    {'name': 'Emily White', 'age': '35', 'condition': 'High Blood Pressure'},
    {'name': 'Michael Green', 'age': '50', 'condition': 'Back Pain'},
    {'name': 'Pavithra', 'age': '22', 'condition': 'Cold'},
    {'name': 'Priyadharshini', 'age': '24', 'condition': 'Fever'},
    {'name': 'Kausika', 'age': '28', 'condition': 'Headache'},
    {'name': 'Arsath', 'age': '30', 'condition': 'Allergy'},
    {'name': 'Pradeepa', 'age': '27', 'condition': 'Stomach Ache'},
  ];

  List<Map<String, String>> _filteredPatients = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPatients = List.from(_patients);

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredPatients = _patients
            .where((patient) =>
        patient['name']!.toLowerCase().contains(query) ||
            patient['condition']!.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getConditionIcon(String condition) {
    if (condition.toLowerCase().contains("fever")) return Icons.local_fire_department;
    if (condition.toLowerCase().contains("headache")) return Icons.psychology;
    if (condition.toLowerCase().contains("diabetes")) return Icons.water_drop;
    if (condition.toLowerCase().contains("blood")) return Icons.favorite;
    if (condition.toLowerCase().contains("cold")) return Icons.ac_unit;
    if (condition.toLowerCase().contains("allergy")) return Icons.grass;
    return Icons.health_and_safety;
  }

  Widget _buildPatientCard(Map<String, String> patient) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.teal.shade400,
          child: Icon(
            _getConditionIcon(patient['condition']!),
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          patient['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Age: ${patient['age']} | Condition: ${patient['condition']}',
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.teal),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Chat with ${patient['name']} coming soon!")),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        title: const Text("Patient Contacts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search by name or condition...",
                  prefixIcon: Icon(Icons.search, color: Colors.teal),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List of patients
            Expanded(
              child: _filteredPatients.isEmpty
                  ? const Center(
                  child: Text("😔 No patients found.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)))
                  : ListView.builder(
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  return _buildPatientCard(_filteredPatients[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
