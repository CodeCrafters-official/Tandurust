import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> steps = [];
  bool isLoading = false;

  final String apiKey = "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";
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  final List<Map<String, dynamic>> categories = [
    {'name': 'Burns', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'name': 'Cuts', 'icon': Icons.healing, 'color': Colors.redAccent},
    {'name': 'Fractures', 'icon': Icons.accessibility_new, 'color': Colors.blue},
    {'name': 'Choking', 'icon': Icons.warning, 'color': Colors.amber},
    {'name': 'Nosebleed', 'icon': Icons.bloodtype, 'color': Colors.purple},
  ];

  final Map<String, String> mockInstructions = {
    'Burns':
    '1. Cool the burn under running water for 10 minutes.\n2. Remove jewelry.\n3. Cover with a clean cloth.\n4. Seek medical help if severe.',
    'Cuts':
    '1. Wash the wound with clean water.\n2. Apply antiseptic.\n3. Cover with sterile bandage.\n4. Change dressing regularly.',
    'Fractures':
    '1. Immobilize the limb.\n2. Apply cold compress.\n3. Do not try to straighten.\n4. Seek immediate medical attention.',
    'Choking':
    '1. Perform Heimlich maneuver.\n2. Call emergency services if needed.',
    'Nosebleed':
    '1. Sit upright.\n2. Pinch the soft part of the nose.\n3. Lean forward.\n4. Apply cold compress.',
  };

  // 🤖 OPENROUTER CALL
  Future<void> getFirstAidInstructions(String query) async {
    setState(() {
      isLoading = true;
      steps = [];
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://tandurust.app",
          "X-Title": "Tandurust First Aid"
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
              "You are a first aid assistant. Give safe, step-by-step first aid instructions in simple language. Number each step."
            },
            {
              "role": "user",
              "content":
              "Provide detailed step-by-step first aid instructions for: $query"
            }
          ],
          "max_tokens": 500,
          "temperature": 0.5
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['choices'][0]['message']['content'] ?? '';

        setState(() {
          steps = rawText
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        });
      } else {
        _useMock(query);
      }
    } catch (e) {
      _useMock(query);
    }

    setState(() => isLoading = false);
  }

  void _useMock(String query) {
    String? mock = mockInstructions[query];
    steps = mock != null ? mock.split('\n') : ["No instructions found."];
  }

  Widget buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => getFirstAidInstructions(category['name']),
      child: Card(
        color: category['color'].withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(category['icon'], color: category['color'], size: 36),
              const SizedBox(height: 8),
              Text(category['name'],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: category['color'])),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callEmergency() async {
    final Uri url = Uri(scheme: 'tel', path: '108');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Aid Guide'), backgroundColor: Colors.teal),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _callEmergency,
        label: const Text("Call 108"),
        icon: const Icon(Icons.phone),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search first aid situation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  getFirstAidInstructions(value.trim());
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => buildCategoryCard(categories[index]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : steps.isEmpty
                  ? const Center(child: Text("Select a condition to see steps"))
                  : Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps
                          .asMap()
                          .entries
                          .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text("${e.key + 1}. ${e.value}",
                            style: const TextStyle(fontSize: 16)),
                      ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
