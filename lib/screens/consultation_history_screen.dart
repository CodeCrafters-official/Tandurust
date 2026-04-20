import 'package:flutter/material.dart';

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  State<ConsultationHistoryScreen> createState() => _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  // Mock consultation history data
  final List<Map<String, String>> _history = [
    {
      'patient': 'Pavithra',
      'date': '01-Sep-2025',
      'condition': 'Fever',
      'notes': 'Prescribed paracetamol and hydration.'
    },
    {
      'patient': 'Priyadharshini',
      'date': '28-Aug-2025',
      'condition': 'Headache',
      'notes': 'Advised rest and mild painkillers.'
    },
    {
      'patient': 'Kausika',
      'date': '20-Aug-2025',
      'condition': 'Diabetes',
      'notes': 'Follow-up on sugar levels, continued medication.'
    },
    {
      'patient': 'Arsath',
      'date': '15-Aug-2025',
      'condition': 'High BP',
      'notes': 'Increased dosage of BP tablets.'
    },
    {
      'patient': 'Pradeepa',
      'date': '10-Aug-2025',
      'condition': 'Back Pain',
      'notes': 'Recommended physiotherapy and posture correction.'
    },
  ];

  List<Map<String, String>> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredHistory = List.from(_history);

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredHistory = _history.where((record) {
          return record['patient']!.toLowerCase().contains(query) ||
              record['condition']!.toLowerCase().contains(query);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHistoryCard(Map<String, String> item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.blue, size: 32),
        title: Text(
          item['patient']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${item['date']}"),
            Text("Condition: ${item['condition']}"),
            Text("Notes: ${item['notes']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consultation History"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by patient name or condition',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Consultation history list
            Expanded(
              child: _filteredHistory.isEmpty
                  ? const Center(child: Text('No records found.'))
                  : ListView.builder(
                itemCount: _filteredHistory.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(_filteredHistory[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
