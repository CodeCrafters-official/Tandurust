import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture placeholder
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade200,
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Placeholder text fields (to be filled dynamically later)
            const Text(
              "Name: ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              "Email: ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              "Phone: ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
