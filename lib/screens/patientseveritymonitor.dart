import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmergencyPatient {
  String name;
  String problem;
  int esiLevel;
  String triageLabel;

  EmergencyPatient({
    required this.name,
    required this.problem,
    required this.esiLevel,
    required this.triageLabel,
  });
}

class EmergencyTriageBoardScreen extends StatefulWidget {
  const EmergencyTriageBoardScreen({super.key});

  @override
  State<EmergencyTriageBoardScreen> createState() =>
      _EmergencyTriageBoardScreenState();
}

class _EmergencyTriageBoardScreenState
    extends State<EmergencyTriageBoardScreen> {

  List<EmergencyPatient> patients = [];

  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final hrCtrl = TextEditingController();
  final sbpCtrl = TextEditingController();
  final spo2Ctrl = TextEditingController();
  final painCtrl = TextEditingController();

  bool unconscious = false;

  String selectedProblem = "Chest Pain";

  // ================= CALL ML BACKEND =================
  Future<void> addPatient() async {
    int chest = selectedProblem == "Chest Pain" ? 1 : 0;
    int sob = selectedProblem == "Shortness of Breath" ? 1 : 0;
    int trauma = selectedProblem == "Trauma / Bleeding" ? 1 : 0;

    // Feature vector (model-compatible)
    List<double> features = [
      double.parse(ageCtrl.text),        // age
      double.parse(sbpCtrl.text),        // systolic BP
      80,                                // diastolic BP (assumed)
      98.6,                              // temperature (assumed)
      1,                                 // gender (ignored)
      chest.toDouble(),
      double.parse(hrCtrl.text),         // heart rate
      double.parse(spo2Ctrl.text),       // SpO2
      sob.toDouble(),
      0,                                 // diabetes (assumed)
      110,                               // blood sugar (assumed)
      18,                                // respiratory rate (assumed)
      double.parse(painCtrl.text) * 10,  // pain
      unconscious ? 1 : 0,               // unconscious
      trauma.toDouble(),
      trauma.toDouble()
    ];

    final response = await http.post(
      Uri.parse("http://51.21.128.88/predict"), // use 127.0.0.1 for web
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"features": features}),
    );

    final data = jsonDecode(response.body);

    setState(() {
      patients.add(
        EmergencyPatient(
          name: nameCtrl.text,
          problem: selectedProblem,
          esiLevel: data["esi_level"],
          triageLabel: data["triage_label"],
        ),
      );

      // Sort by urgency (ESI 1 first)
      patients.sort((a, b) => a.esiLevel.compareTo(b.esiLevel));
    });

    nameCtrl.clear();
    ageCtrl.clear();
    hrCtrl.clear();
    sbpCtrl.clear();
    spo2Ctrl.clear();
    painCtrl.clear();
    unconscious = false;
  }

  Color severityColor(int esi) {
    if (esi <= 2) return Colors.red;
    if (esi == 3) return Colors.orange;
    return Colors.green;
  }

  void markTreated(EmergencyPatient p) {
    setState(() {
      patients.remove(p);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${p.name} treated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ER Smart Triage Board"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ================= INPUT =================
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Patient Name"),
            ),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Age"),
            ),
            TextField(
              controller: hrCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Heart Rate"),
            ),
            TextField(
              controller: sbpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Systolic BP"),
            ),
            TextField(
              controller: spo2Ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "SpO₂ (%)"),
            ),

            SwitchListTile(
              title: const Text("Unconscious"),
              value: unconscious,
              onChanged: (v) => setState(() => unconscious = v),
            ),

            DropdownButton<String>(
              value: selectedProblem,
              items: const [
                DropdownMenuItem(value: "Chest Pain", child: Text("Chest Pain")),
                DropdownMenuItem(value: "Shortness of Breath", child: Text("Shortness of Breath")),
                DropdownMenuItem(value: "Trauma / Bleeding", child: Text("Trauma / Bleeding")),
                DropdownMenuItem(value: "Severe Pain", child: Text("Severe Pain")),
              ],
              onChanged: (v) => setState(() => selectedProblem = v!),
            ),

            TextField(
              controller: painCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Pain (0–10)"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: addPatient,
              child: const Text("Add Patient"),
            ),

            const Divider(),

            // ================= QUEUE =================
            Expanded(
              child: patients.isEmpty
                  ? const Center(child: Text("No patients waiting"))
                  : ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final p = patients[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: severityColor(p.esiLevel),
                        child: Text(
                          "ESI ${p.esiLevel}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Text("${p.problem}\n${p.triageLabel}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.check, color: Colors.teal),
                        onPressed: () => markTreated(p),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
