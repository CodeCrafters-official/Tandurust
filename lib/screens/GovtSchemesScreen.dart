import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GovtSchemesScreen extends StatefulWidget {
  const GovtSchemesScreen({super.key});

  @override
  State<GovtSchemesScreen> createState() => _GovtSchemesScreenState();
}

class _GovtSchemesScreenState extends State<GovtSchemesScreen> {
  String query = "";

  // Health-focused schemes
  final List<Map<String, String>> schemes = [
    {
      "name": "Ayushman Bharat - PMJAY",
      "eligibility": "Low-income families listed in SECC database.",
      "benefits":
      "Cashless health insurance coverage of ₹5 lakh per family per year for secondary and tertiary care hospitalization.",
      "apply": "Apply through nearest CSC center or online portal.",
      "link": "https://pmjay.gov.in",
      "icon": "local_hospital"
    },
    {
      "name": "Pradhan Mantri Jan Arogya Yojana (PMJAY) Preventive Care",
      "eligibility": "All families registered under Ayushman Bharat.",
      "benefits":
      "Covers preventive health checkups, early detection of NCDs, and awareness campaigns.",
      "apply": "Register online via PMJAY portal or visit nearest health center.",
      "link": "https://pmjay.gov.in",
      "icon": "medication"
    },
    {
      "name": "Maternity Benefit Scheme (Pradhan Mantri Matru Vandana Yojana)",
      "eligibility": "Pregnant women from low-income households.",
      "benefits": "Financial assistance of ₹6,000 during pregnancy for nutrition and medical care.",
      "apply": "Register at local PHC or government hospital.",
      "link": "https://wcd.nic.in",
      "icon": "pregnant_woman"
    },
    {
      "name": "Janani Suraksha Yojana",
      "eligibility": "Pregnant women delivering in government health facilities.",
      "benefits": "Cash incentives for institutional delivery and safe motherhood.",
      "apply": "Enroll at nearest government hospital or health center.",
      "link": "https://nhm.gov.in",
      "icon": "child_care"
    },
    {
      "name": "National Health Mission (NHM)",
      "eligibility": "All Indian citizens.",
      "benefits":
      "Provides comprehensive primary, secondary, and tertiary healthcare through public health systems, vaccination, and outreach programs.",
      "apply": "Visit local health centers or state NHM portals.",
      "link": "https://nhm.gov.in",
      "icon": "healing"
    },
    {
      "name": "Tuberculosis Free India Initiative",
      "eligibility": "All citizens, free testing for suspected TB patients.",
      "benefits": "Free diagnosis and treatment for TB under government programs.",
      "apply": "Register at nearest government hospital or TB clinic.",
      "link": "https://tbcindia.gov.in",
      "icon": "coronavirus"
    },
    {
      "name": "National AIDS Control Program (NACP)",
      "eligibility": "High-risk groups and general population for HIV testing.",
      "benefits":
      "Free HIV testing, counseling, ART treatment, and awareness campaigns.",
      "apply": "Visit government ART center or district NACO office.",
      "link": "https://naco.gov.in",
      "icon": "virus"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSchemes = schemes
        .where((scheme) =>
        scheme["name"]!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Schemes"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search schemes...",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                setState(() {
                  query = val;
                });
              },
            ),
          ),

          // Schemes List
          Expanded(
            child: ListView.builder(
              itemCount: filteredSchemes.length,
              itemBuilder: (context, index) {
                final scheme = filteredSchemes[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                  child: ExpansionTile(
                    leading: Icon(
                      _getIcon(scheme["icon"]!),
                      color: Colors.teal,
                    ),
                    title: Text(
                      scheme["name"]!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    children: [
                      _buildDetailRow("Eligibility", scheme["eligibility"]!),
                      _buildDetailRow("Benefits", scheme["benefits"]!),
                      _buildDetailRow("How to Apply", scheme["apply"]!),
                      const SizedBox(height: 8),

                      // Quick Apply Button
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 12),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final url = Uri.parse(scheme["link"]!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text("Could not open application link."),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Quick Apply"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case "local_hospital":
        return Icons.local_hospital;
      case "medication":
        return Icons.medication;
      case "pregnant_woman":
        return Icons.pregnant_woman;
      case "child_care":
        return Icons.child_care;
      case "healing":
        return Icons.healing;
      case "coronavirus":
        return Icons.coronavirus;
      case "virus":
        return Icons.coronavirus; // placeholder for HIV
      default:
        return Icons.account_balance;
    }
  }
}
