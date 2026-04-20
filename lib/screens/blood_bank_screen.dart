import 'package:flutter/material.dart';

class BloodBankScreen extends StatefulWidget {
  const BloodBankScreen({super.key});

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isAvailable = false; // Donor availability toggle

  // Mock "my wallet" donor data
  final Map<String, String> donorData = {
    "id": "DONOR1234",
    "name": "Ravi Kumar",
    "bloodGroup": "O+",
    "lastDonation": "12 Aug 2025",
    "location": "Chennai"
  };

  // Mock donors for the map (with relative positions 0..1)
  final List<Map<String, dynamic>> donors = [
    {
      "name": "Anita",
      "bloodGroup": "A+",
      "distance": "1.2 km",
      "lastDonation": "05 Jul 2025",
      "pos": const Offset(0.30, 0.42),
    },
    {
      "name": "Rahul",
      "bloodGroup": "B-",
      "distance": "2.6 km",
      "lastDonation": "10 Jun 2025",
      "pos": const Offset(0.62, 0.70),
    },
    {
      "name": "Priya",
      "bloodGroup": "O+",
      "distance": "0.9 km",
      "lastDonation": "25 Aug 2025",
      "pos": const Offset(0.80, 0.25),
    },
    {
      "name": "Karthik",
      "bloodGroup": "AB+",
      "distance": "3.1 km",
      "lastDonation": "18 May 2025",
      "pos": const Offset(0.48, 0.55),
    },
    // --- Added New People ---
    {
      "name": "Nithin",
      "bloodGroup": "B+",
      "distance": "1.8 km",
      "lastDonation": "20 Aug 2025",
      "pos": const Offset(0.25, 0.65),
    },
    {
      "name": "Pavithra",
      "bloodGroup": "A-",
      "distance": "2.0 km",
      "lastDonation": "30 Jul 2025",
      "pos": const Offset(0.55, 0.20),
    },
    {
      "name": "Priyadharshini",
      "bloodGroup": "O+",
      "distance": "1.5 km",
      "lastDonation": "15 Aug 2025",
      "pos": const Offset(0.70, 0.60),
    },
    {
      "name": "Kausika",
      "bloodGroup": "AB-",
      "distance": "3.5 km",
      "lastDonation": "10 May 2025",
      "pos": const Offset(0.40, 0.30),
    },
    {
      "name": "Mohamed Arsath",
      "bloodGroup": "B+",
      "distance": "0.7 km",
      "lastDonation": "28 Aug 2025",
      "pos": const Offset(0.15, 0.50),
    },
    {
      "name": "Lakshmi Pradeepa",
      "bloodGroup": "A+",
      "distance": "2.8 km",
      "lastDonation": "12 Jun 2025",
      "pos": const Offset(0.85, 0.45),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDonorDetails(Map<String, dynamic> donor) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.bloodtype, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        donor["name"],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Chip(
                      label: Text(
                        donor["bloodGroup"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text("Approx. ${donor["distance"]} away"),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text("Last donation: ${donor["lastDonation"]}"),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                Text("Request sent to ${donor["name"]}")),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text("Request Blood"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Message thread with ${donor["name"]} (coming soon)")),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("Message"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Blood Bank"),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wallet), text: "Wallet"),
            Tab(icon: Icon(Icons.location_on), text: "Live Radar"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletTab(),
          _buildRadarTab(),
        ],
      ),
    );
  }

  /// --------- WALLET TAB ----------
  Widget _buildWalletTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Your Digital Blood Wallet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Donor details
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row("Name", donorData["name"]!),
                  _row("Blood Group", donorData["bloodGroup"]!),
                  _row("Last Donation", donorData["lastDonation"]!),
                  _row("Location", donorData["location"]!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Update Donor Info feature coming soon")),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text("Update Donor Info"),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text("$label: ",
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// --------- RADAR TAB ----------
  Widget _buildRadarTab() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            "Available for Donation",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text("Toggle if you’re ready to donate"),
          value: isAvailable,
          onChanged: (val) => setState(() => isAvailable = val),
          secondary: Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
          ),
        ),

        // Mock Map with Donor Pins (local asset to avoid network issues)
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Static Map Image from assets
                        Positioned.fill(
                          child: Image.asset(
                            'assets/mock_map.png',
                            fit: BoxFit.cover,
                            // Fallback UI if asset missing
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Text(
                                  "Map image not found",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              );
                            },
                          ),
                        ),

                        // Donor pins overlay (tappable)
                        ...donors.map((d) {
                          final pos = d["pos"] as Offset;
                          final left = pos.dx * constraints.maxWidth - 16;
                          final top = pos.dy * constraints.maxHeight - 32;
                          return Positioned(
                            left: left.clamp(0, constraints.maxWidth - 32),
                            top: top.clamp(0, constraints.maxHeight - 32),
                            child: GestureDetector(
                              onTap: () => _showDonorDetails(d),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
