import 'package:flutter/material.dart';

class PatientReportsScreen extends StatelessWidget {
  const PatientReportsScreen({super.key});

  // Mock reports data
  final List<Map<String, String>> reports = const [
    {
      "title": "Blood Test Report",
      "date": "20 Aug 2025",
      "type": "Lab Report",
      "status": "Available"
    },
    {
      "title": "X-Ray Scan",
      "date": "15 Aug 2025",
      "type": "Lab Report",
      "status": "Available"
    },
    {
      "title": "Prescription – Dr. Mehta",
      "date": "05 Aug 2025",
      "type": "Prescription",
      "status": "Available"
    },
    {
      "title": "Discharge Summary",
      "date": "30 Jul 2025",
      "type": "Hospital",
      "status": "Available"
    },
    {
      "title": "Urine Test Report",
      "date": "Pending",
      "type": "Lab Report",
      "status": "Pending"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = reports[index];
          final isPending = report["status"] == "Pending";

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending ? Colors.orange : Colors.indigo,
                child: Icon(
                  isPending ? Icons.hourglass_empty : Icons.assignment,
                  color: Colors.white,
                ),
              ),
              title: Text(
                report["title"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${report["type"]} • ${report["date"]}",
                style: const TextStyle(color: Colors.black54),
              ),
              trailing: isPending
                  ? const Text(
                "Pending",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.picture_as_pdf,
                    color: Colors.indigo),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Opening ${report["title"]} (mock PDF)…"),
                    ),
                  );
                },
              ),
              onTap: () {
                if (!isPending) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Viewing details of ${report["title"]}… (coming soon)"),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
