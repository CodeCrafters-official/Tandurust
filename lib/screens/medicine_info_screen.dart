// file: medicine_availability_screen.dart
import 'package:flutter/material.dart';

class MedicineAvailabilityScreen extends StatefulWidget {
  const MedicineAvailabilityScreen({super.key});

  @override
  State<MedicineAvailabilityScreen> createState() =>
      _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState
    extends State<MedicineAvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock medicine database
  final List<Map<String, dynamic>> _medicines = [
    {
      'name': 'Paracetamol 500mg',
      'expiry': '2026-05-01',
      'authentic': true,
      'pharmacies': [
        {'name': 'City Pharmacy', 'distance': '1.2 km'},
        {'name': 'HealthPlus', 'distance': '2.5 km'},
      ],
    },
    {
      'name': 'Amoxicillin 250mg',
      'expiry': '2024-12-15',
      'authentic': false,
      'pharmacies': [
        {'name': 'Care Pharmacy', 'distance': '0.8 km'},
      ],
    },
    {
      'name': 'Cough Syrup',
      'expiry': '2025-03-20',
      'authentic': true,
      'pharmacies': [
        {'name': 'Wellness Pharmacy', 'distance': '1.5 km'},
        {'name': 'City Pharmacy', 'distance': '1.2 km'},
      ],
    },
    {
      'name': 'Ibuprofen 400mg',
      'expiry': '2025-11-10',
      'authentic': true,
      'pharmacies': [
        {'name': 'HealthPlus', 'distance': '2.5 km'},
        {'name': 'Care Pharmacy', 'distance': '0.8 km'},
      ],
    },
    {
      'name': 'Metformin 500mg',
      'expiry': '2026-01-15',
      'authentic': true,
      'pharmacies': [
        {'name': 'City Pharmacy', 'distance': '1.2 km'},
        {'name': 'Wellness Pharmacy', 'distance': '1.5 km'},
      ],
    },
    {
      'name': 'Vitamin C 500mg',
      'expiry': '2027-08-30',
      'authentic': true,
      'pharmacies': [
        {'name': 'HealthPlus', 'distance': '2.5 km'},
        {'name': 'Care Pharmacy', 'distance': '0.8 km'},
      ],
    },
    {
      'name': 'Dextromethorphan Syrup',
      'expiry': '2025-06-12',
      'authentic': false,
      'pharmacies': [
        {'name': 'Wellness Pharmacy', 'distance': '1.5 km'},
      ],
    },
    {
      'name': 'Cetirizine 10mg',
      'expiry': '2025-09-01',
      'authentic': true,
      'pharmacies': [
        {'name': 'City Pharmacy', 'distance': '1.2 km'},
        {'name': 'Care Pharmacy', 'distance': '0.8 km'},
      ],
    },
    {
      'name': 'Omeprazole 20mg',
      'expiry': '2026-03-25',
      'authentic': true,
      'pharmacies': [
        {'name': 'HealthPlus', 'distance': '2.5 km'},
      ],
    },
    {
      'name': 'Azithromycin 500mg',
      'expiry': '2024-10-10',
      'authentic': false,
      'pharmacies': [
        {'name': 'Wellness Pharmacy', 'distance': '1.5 km'},
      ],
    },
  ];

  List<Map<String, dynamic>> _searchResults = [];

  void _searchMedicine(String query) {
    final results = _medicines
        .where((medicine) =>
        medicine['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _searchResults = results;
    });
  }

  // Mock QR scan function
  void _mockQRScan() {
    // For mock, randomly pick a medicine from the list
    final scannedMedicine =
        (_medicines..shuffle()).first; // pick a random medicine

    // Show dialog with scanned medicine info
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR Scanned Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scannedMedicine['name'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Expiry: ${scannedMedicine['expiry']}',
                style: TextStyle(
                  color: DateTime.parse(scannedMedicine['expiry'])
                      .isBefore(DateTime.now())
                      ? Colors.red
                      : Colors.green,
                )),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  scannedMedicine['authentic']
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: scannedMedicine['authentic'] ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(scannedMedicine['authentic'] ? 'Authentic' : 'Counterfeit'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Info & Availability'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search medicine...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _searchMedicine,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.teal,
                  onPressed: _mockQRScan,
                  child: const Icon(Icons.qr_code_scanner),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(child: Text('No medicine selected'))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final med = _searchResults[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['name'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Expiry: '),
                              Text(
                                med['expiry'],
                                style: TextStyle(
                                    color: DateTime.parse(med['expiry'])
                                        .isBefore(DateTime.now())
                                        ? Colors.red
                                        : Colors.green),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                med['authentic']
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: med['authentic']
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(med['authentic']
                                  ? 'Authentic'
                                  : 'Counterfeit'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Available at:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          ...med['pharmacies'].map<Widget>((pharmacy) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.local_pharmacy,
                                  color: Colors.teal),
                              title: Text(pharmacy['name']),
                              trailing: Text(pharmacy['distance']),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
