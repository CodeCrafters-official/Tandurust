// lib/screens/symptom_checker_v2.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// AI-like offline symptom checker (heuristic)
/// NOT a medical diagnosis — only a decision support / triage helper.
///
/// UI: - checkbox symptom selection
///     - "Analyze" builds ranked list of possible conditions
///     - each result shows confidence %, matched symptoms, missing key symptoms, and advice
///     - emergency banner/button appears if urgent condition is highly matched
class SymptomCheckerV2 extends StatefulWidget {
  const SymptomCheckerV2({super.key});

  @override
  State<SymptomCheckerV2> createState() => _SymptomCheckerV2State();
}

class _SymptomCheckerV2State extends State<SymptomCheckerV2> {
  // Master symptom list (UI)
  final List<String> allSymptoms = [
    "Fever",
    "Cough",
    "Headache",
    "Rash",
    "Chest Pain",
    "Fatigue",
    "Nausea",
    "Vomiting",
    "Sore Throat",
    "Runny Nose",
    "Diarrhea",
    "Shortness of Breath",
    "Body Pain",
    "Loss of Taste",
    "Loss of Smell",
    "Dizziness",
    "High Temperature (>=38°C / 100.4°F)",
    "Rapid Heartbeat",
    "Confusion or Disorientation",
    "Severe Abdominal Pain"
  ];

  // Conditions knowledge base:
  // - prior: baseline prevalence estimate (0..1)
  // - weights: symptom -> importance (0..1)
  // - advice: textual suggestions
  // - emergency: whether this condition can be an emergency
  final List<Map<String, dynamic>> conditions = [
    {
      "name": "Common Cold",
      "prior": 0.25,
      "weights": {
        "Runny Nose": 0.9,
        "Cough": 0.6,
        "Sore Throat": 0.6,
        "Fever": 0.2,
        "Headache": 0.2
      },
      "advice":
      "Likely mild. Rest, fluids, steam inhalation. OTC symptom relief (paracetamol) as needed. See doctor if symptoms worsen or persist >7–10 days.",
      "emergency": false
    },
    {
      "name": "Influenza (Flu)",
      "prior": 0.12,
      "weights": {
        "Fever": 0.9,
        "Cough": 0.7,
        "Body Pain": 0.7,
        "Fatigue": 0.6,
        "Headache": 0.5
      },
      "advice":
      "Moderate. Rest, hydration, antipyretics for fever. If severe respiratory symptoms, seek medical care.",
      "emergency": false
    },
    {
      "name": "COVID-19 (possible)",
      "prior": 0.08,
      "weights": {
        "Fever": 0.8,
        "Cough": 0.7,
        "Loss of Taste": 0.9,
        "Loss of Smell": 0.9,
        "Fatigue": 0.5,
        "Shortness of Breath": 0.7
      },
      "advice":
      "Possible. Consider testing and isolation. Seek care if shortness of breath, persistent chest pain, or confusion.",
      "emergency": false
    },
    {
      "name": "Gastroenteritis / Food Poisoning",
      "prior": 0.06,
      "weights": {
        "Nausea": 0.9,
        "Vomiting": 0.9,
        "Diarrhea": 0.9,
        "Fever": 0.3,
      },
      "advice":
      "Hydration (ORS), rest. If unable to retain fluids, blood in stool, very high fever or dizziness, see a physician.",
      "emergency": false
    },
    {
      "name": "Acute Coronary Syndrome / Heart Problem",
      "prior": 0.02,
      "weights": {
        "Chest Pain": 1.0,
        "Shortness of Breath": 0.8,
        "Dizziness": 0.6,
        "Rapid Heartbeat": 0.7,
        "Confusion or Disorientation": 0.5
      },
      "advice":
      "Potential emergency — call emergency services immediately if chest pain, pressure, fainting, or severe shortness of breath.",
      "emergency": true
    },
    {
      "name": "Migraine",
      "prior": 0.05,
      "weights": {
        "Headache": 1.0,
        "Nausea": 0.4,
        "Dizziness": 0.4,
      },
      "advice":
      "Often severe one-sided headache with nausea; rest in a dark quiet room. Seek care if new type of severe headache, sudden onset, or neurological signs.",
      "emergency": false
    },
    {
      "name": "Allergic Reaction / Anaphylaxis (severe)",
      "prior": 0.01,
      "weights": {
        "Rash": 0.7,
        "Shortness of Breath": 0.9,
        "Dizziness": 0.6,
        "Swelling": 0.8, // note: 'Swelling' might not be in allSymptoms — fine
      },
      "advice":
      "If breathing difficulty, throat swelling or dizziness — emergency. Use epinephrine if prescribed and call emergency services.",
      "emergency": true
    },
    {
      "name": "Normal/Lower-Risk Fever (viral)",
      "prior": 0.20,
      "weights": {
        "Fever": 1.0,
        "Fatigue": 0.4,
        "Headache": 0.3,
      },
      "advice":
      "Many viral infections cause isolated fever. Monitor temperature, hydrate. Seek doctor if fever >3 days or severe symptoms develop.",
      "emergency": false
    }
  ];

  final List<String> selectedSymptoms = [];
  List<Map<String, dynamic>> rankedResults = [];

  // Analyze using a simple explainable scoring formula:
  // - match_sum = sum(weights for matched symptoms)
  // - total_possible = sum(all weights for that condition)
  // - match_fraction = match_sum / total_possible
  // - final_score = 0.55 * match_fraction + 0.45 * prior  (weights chosen to favor observed symptoms)
  void analyze() {
    final List<Map<String, dynamic>> results = [];

    for (var cond in conditions) {
      final Map<String, double> weights =
      Map<String, double>.from(cond['weights'] as Map);

      double matchSum = 0.0;
      double totalPossible = 0.0;
      final List<String> matched = [];
      final List<String> missingKey = [];

      weights.forEach((symptom, w) {
        totalPossible += w;
        if (selectedSymptoms.contains(symptom)) {
          matchSum += w;
          matched.add(symptom);
        } else {
          // if weight is high and missing — mark as important missing symptom
          if (w >= 0.7) missingKey.add(symptom);
        }
      });

      final double matchFraction =
      totalPossible > 0 ? (matchSum / totalPossible) : 0.0;
      final double prior = (cond['prior'] as num).toDouble();
      final double finalScore = (0.55 * matchFraction) + (0.45 * prior);

      results.add({
        'name': cond['name'],
        'score': finalScore,
        'matchFraction': matchFraction,
        'matched': matched,
        'missingKey': missingKey,
        'urgency': cond['advice'],
        'emergency': cond['emergency'],
        'prior': prior
      });
    }

    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    setState(() {
      rankedResults = results.take(5).toList(); // top 5
    });
  }

  void clearAll() {
    setState(() {
      selectedSymptoms.clear();
      rankedResults.clear();
    });
  }

  String confidenceLabel(double v) {
    if (v >= 0.75) return "Likely";
    if (v >= 0.45) return "Possible";
    return "Less likely";
  }

  Color confidenceColor(double v) {
    if (v >= 0.75) return Colors.redAccent;
    if (v >= 0.45) return Colors.orange;
    return Colors.green;
  }

  Future<void> _callEmergency() async {
    final Uri tel = Uri.parse('tel:112'); // use local emergency number if different
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  Widget _explainChip(String text, {bool positive = true}) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: positive ? Colors.teal.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: positive ? Colors.teal.withOpacity(0.4) : Colors.red.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: positive ? Colors.teal.shade800 : Colors.red.shade800, fontSize: 13),
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final emergencyMatch = rankedResults.isNotEmpty &&
        (rankedResults.first['emergency'] == true) &&
        (rankedResults.first['score'] as double) >= 0.6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (emergencyMatch)
              Container(
                color: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Possible emergency detected. If symptoms are severe (chest pain, fainting, severe breathlessness), call emergency services now.',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _callEmergency,
                      icon: const Icon(Icons.call, color: Colors.red),
                      label: const Text('Call', style: TextStyle(color: Colors.red)),
                    )
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Select symptoms you have",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            children: [
                              Text(
                                "Tap boxes below — choose all that apply.",
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          // Symptoms checkboxes in two-column layout
                          LayoutBuilder(builder: (context, constraints) {
                            final cross = constraints.maxWidth >= 600 ? 3 : 2;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: allSymptoms.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  childAspectRatio: 3.5,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4),
                              itemBuilder: (context, index) {
                                final s = allSymptoms[index];
                                final picked = selectedSymptoms.contains(s);
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (picked) {
                                        selectedSymptoms.remove(s);
                                      } else {
                                        selectedSymptoms.add(s);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                        color: picked ? Colors.teal.shade50 : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: picked,
                                          activeColor: Colors.teal,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) selectedSymptoms.add(s);
                                              else selectedSymptoms.remove(s);
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Text(
                                            s,
                                            softWrap: true,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: analyze,
                                icon: const Icon(Icons.analytics),
                                label: const Text("Analyze"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: clearAll,
                                icon: const Icon(Icons.clear),
                                label: const Text("Clear"),
                              ),
                              const Spacer(),
                              Text("${selectedSymptoms.length} selected",
                                  style: const TextStyle(fontSize: 13, color: Colors.black54))
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Results
                  if (rankedResults.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            const Text("No analysis yet",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text("Select symptoms and tap Analyze to get suggestions."),
                          ],
                        ),
                      ),
                    )
                  else
                    ...rankedResults.map((cond) {
                      final double score = (cond['score'] as double);
                      final double matchFraction = (cond['matchFraction'] as double);
                      final List matched = cond['matched'] as List;
                      final List missing = cond['missingKey'] as List;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // header row with name and percent
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cond['name'],
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("${(score * 100).toStringAsFixed(0)}%",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: confidenceColor(score))),
                                      Text(confidenceLabel(score),
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  )
                                ],
                              ),

                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: score.clamp(0.0, 1.0),
                                color: confidenceColor(score),
                                backgroundColor: Colors.grey.shade200,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 10),

                              // Matched symptoms chips
                              if (matched.isNotEmpty) ...[
                                const Text("Matched symptoms:", style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Wrap(
                                  children: matched.map<Widget>((m) => _explainChip(m, positive: true)).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Important missing symptoms
                              if (missing.isNotEmpty) ...[
                                const Text("Important symptoms not present:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 6),
                                Wrap(
                                  children: missing.map<Widget>((m) => _explainChip(m, positive: false)).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Advice
                              Text("Advice:", style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(cond['urgency'] ?? '', style: const TextStyle(color: Colors.black87)),

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // If emergency and high confidence -> dial emergency
                                      if ((cond['emergency'] as bool) && score >= 0.6) {
                                        _callEmergency();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Consider contacting a healthcare provider for "${cond['name']}".')),
                                        );
                                      }
                                    },
                                    icon: Icon((cond['emergency'] as bool) ? Icons.local_hospital : Icons.contact_phone),
                                    label: Text((cond['emergency'] as bool) ? "Emergency" : "Contact Doctor"),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: (cond['emergency'] as bool) ? Colors.red : Colors.teal),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(cond['name']),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("Confidence: ${(score * 100).toStringAsFixed(0)}%"),
                                                const SizedBox(height: 8),
                                                if (matched.isNotEmpty) ...[
                                                  const Text("Matched symptoms:"),
                                                  Wrap(children: matched.map<Widget>((m) => _explainChip(m)).toList()),
                                                  const SizedBox(height: 8),
                                                ],
                                                if (missing.isNotEmpty) ...[
                                                  const Text("Important symptoms not present:"),
                                                  Wrap(children: missing.map<Widget>((m) => _explainChip(m, positive:false)).toList()),
                                                  const SizedBox(height: 8),
                                                ],
                                                Text("Advice:\n${cond['urgency'] ?? ''}"),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text("Details"),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
