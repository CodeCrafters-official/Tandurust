import 'package:flutter/material.dart';

class PandemicModeScreen extends StatelessWidget {
  const PandemicModeScreen({super.key});

  /// ALERT BANNER
  Widget alertBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Emergency surge detected. Hospitals nearing capacity.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// SURGE CARD
  Widget surgeCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.4)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  /// SECTION WRAPPER
  Widget sectionCard(String title, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  /// HOSPITAL BAR
  Widget hospitalTile(String name, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value,
            minHeight: 10,
            color: value > .9
                ? Colors.red
                : value > .7
                ? Colors.orange
                : Colors.green,
          ),
          const SizedBox(height: 6),
          Text("${(value * 100).toInt()}% ICU Occupied",
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// HEAT DOT
  Widget heatDot(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(.7),
            color.withOpacity(.2),
            Colors.transparent
          ],
        ),
      ),
    );
  }

  /// TRIAGE CHIP
  Widget triageChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pandemic Mode"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            alertBanner(),
            const SizedBox(height: 20),

            /// PATIENT SURGE
            sectionCard(
              "Patient Surge Summary",
              Row(
                children: [
                  surgeCard("Critical", "24", Colors.red),
                  const SizedBox(width: 10),
                  surgeCard("Serious", "41", Colors.orange),
                  const SizedBox(width: 10),
                  surgeCard("Stable", "63", Colors.green),
                ],
              ),
            ),

            /// 🔥 HEATMAP (WORKS ON PHONE + WEB)
            sectionCard(
              "City Heatmap",
              AspectRatio(
                aspectRatio: 2.6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          "assets/chennai_map.png",
                          fit: BoxFit.cover,
                        ),
                      ),

                      Positioned(left: 150, top: 110, child: heatDot(Colors.red)),
                      Positioned(left: 240, top: 160, child: heatDot(Colors.orange)),
                      Positioned(left: 360, top: 90, child: heatDot(Colors.red)),
                      Positioned(left: 520, top: 140, child: heatDot(Colors.orange)),
                      Positioned(left: 650, top: 120, child: heatDot(Colors.yellow)),
                    ],
                  ),
                ),
              ),
            ),

            /// HOSPITAL CAPACITY
            sectionCard(
              "Hospital ICU Capacity",
              Column(
                children: [
                  hospitalTile("City Hospital", .90),
                  hospitalTile("Apollo Hospital", .75),
                  hospitalTile("Gov Hospital", .98),
                ],
              ),
            ),

            /// TRIAGE BOARD
            sectionCard(
              "Mass Triage Board",
              Row(
                children: [
                  Expanded(child: Column(children: [
                    const Text("Critical", style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold)),
                    triageChip("Cardiac Arrest", Colors.red),
                    triageChip("Oxygen Failure", Colors.red),
                  ])),
                  Expanded(child: Column(children: [
                    const Text("Serious", style: TextStyle(color: Colors.orange,fontWeight: FontWeight.bold)),
                    triageChip("Breathing Issue", Colors.orange),
                    triageChip("High Fever", Colors.orange),
                  ])),
                  Expanded(child: Column(children: [
                    const Text("Stable", style: TextStyle(color: Colors.green,fontWeight: FontWeight.bold)),
                    triageChip("Minor Injury", Colors.green),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
