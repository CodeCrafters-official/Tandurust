import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthTipsScreen extends StatefulWidget {
  @override
  _HealthTipsScreenState createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final List<String> healthProblems = [
    'Diabetes','Hypertension','Arthritis','Heart Disease',
    'Asthma','Allergies','Cholesterol','Obesity',
    'Osteoporosis','Depression','Migraine',
  ];

  List<String> filteredProblems = [];
  String selectedProblem = '';
  String healthTips = '';
  bool isLoading = false;

  final TextEditingController _controller = TextEditingController();

  /// 🔐 PASTE YOUR NEW OPENROUTER KEY HERE
  final String apiKey = "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";
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  @override
  void initState() {
    super.initState();
    filteredProblems = healthProblems;
  }

  void _filterProblems(String query) {
    setState(() {
      filteredProblems = healthProblems
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // 🤖 FETCH HEALTH TIPS FROM OPENROUTER
  Future<void> fetchHealthTips(String problem) async {
    setState(() {
      selectedProblem = problem;
      isLoading = true;
      healthTips = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://tandurust.app",
          "X-Title": "Tandurust Health App"
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
              "You are a helpful health assistant. Give simple lifestyle and diet tips. Do not give medical diagnosis."
            },
            {
              "role": "user",
              "content": "Give simple health tips for $problem"
            }
          ],
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          healthTips = decoded['choices'][0]['message']['content'];
        });
      } else {
        setState(() {
          healthTips = "API Error ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        healthTips = "Error: $e";
      });
    }

    setState(() => isLoading = false);
  }

  // UI widgets unchanged below 👇

  Widget _buildSearchBar() {
    return TextField(
      controller: _controller,
      onChanged: _filterProblems,
      onSubmitted: (v) => fetchHealthTips(v),
      decoration: InputDecoration(
        hintText: 'Search or type a health problem',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSuggestionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredProblems.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filteredProblems[index]),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _controller.text = filteredProblems[index];
          fetchHealthTips(filteredProblems[index]);
        },
      ),
    );
  }

  Widget _buildHealthTips() {
    if (selectedProblem.isEmpty) return SizedBox();

    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : Text(healthTips, style: TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Tips")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            _buildSuggestionList(),
            _buildHealthTips(),
          ],
        ),
      ),
    );
  }
}
