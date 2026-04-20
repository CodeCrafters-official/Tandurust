import 'package:flutter/material.dart';

class MedicineAvailabilityScreen extends StatefulWidget {
  @override
  _MedicineAvailabilityScreenState createState() =>
      _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState
    extends State<MedicineAvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String sortOption = "Default";

  // Mock pharmacy + medicine data
  final List<Map<String, dynamic>> pharmacies = [
    {
      'name': 'HealthPlus Pharmacy',
      'address': 'Main Street, Nabha',
      'distance': 2.0, // in km
      'stock': {
        'Paracetamol': 12,
        'Amoxicillin': 5,
        'Cough Syrup': 8,
      }
    },
    {
      'name': 'CareWell Medicals',
      'address': 'Market Road, Nabha',
      'distance': 1.2,
      'stock': {
        'Paracetamol': 0,
        'Ibuprofen': 20,
        'Vitamin C': 15,
      }
    },
    {
      'name': 'CityLife Pharmacy',
      'address': 'Bus Stand, Nabha',
      'distance': 3.5,
      'stock': {
        'Insulin': 3,
        'Paracetamol': 7,
        'Cough Syrup': 0,
      }
    },
  ];

  List<Map<String, dynamic>> getSortedPharmacies() {
    List<Map<String, dynamic>> sortedList = List.from(pharmacies);

    if (sortOption == "Nearest First") {
      sortedList.sort((a, b) => a['distance'].compareTo(b['distance']));
    } else if (sortOption == "Most Stock First") {
      sortedList.sort((a, b) {
        int aStock = (a['stock'] as Map<String, int>).values.fold(0, (x, y) => x + y);
        int bStock = (b['stock'] as Map<String, int>).values.fold(0, (x, y) => x + y);
        return bStock.compareTo(aStock);
      });
    }

    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final sortedPharmacies = getSortedPharmacies();

    return Scaffold(
      appBar: AppBar(
        title: Text("Medicine Availability"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search medicine (e.g., Paracetamol)",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Sorting dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text("Sort by: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: sortOption,
                  items: [
                    "Default",
                    "Nearest First",
                    "Most Stock First"
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      sortOption = val!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Display filtered pharmacies
          Expanded(
            child: ListView.builder(
              itemCount: sortedPharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = sortedPharmacies[index];
                final stock = pharmacy['stock'] as Map<String, int>;

                // Filter medicines based on search
                final filteredStock = stock.entries
                    .where((entry) =>
                searchQuery.isEmpty ||
                    entry.key.toLowerCase().contains(searchQuery))
                    .toList();

                if (filteredStock.isEmpty) return SizedBox.shrink();

                return Card(
                  margin: EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ExpansionTile(
                    leading: Icon(Icons.local_pharmacy, color: Colors.teal),
                    title: Text(pharmacy['name'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${pharmacy['address']} • ${pharmacy['distance']} km"),
                    children: filteredStock.map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        trailing: entry.value > 0
                            ? Text(
                          "Available: ${entry.value}",
                          style: TextStyle(color: Colors.green),
                        )
                            : Text(
                          "Out of Stock",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
