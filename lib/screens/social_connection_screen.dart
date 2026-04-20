// lib/screens/contacts_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreens extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreens> {
  List<Map<String, String>> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('contact_names') ?? [];
    final numbers = prefs.getStringList('contact_numbers') ?? [];

    setState(() {
      contacts = List.generate(
        names.length,
            (index) => {'name': names[index], 'number': numbers[index]},
      );
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final names = contacts.map((c) => c['name']!).toList();
    final numbers = contacts.map((c) => c['number']!).toList();

    await prefs.setStringList('contact_names', names);
    await prefs.setStringList('contact_numbers', numbers);
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Contact"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  numberController.text.isNotEmpty) {
                setState(() {
                  contacts.add({
                    'name': nameController.text,
                    'number': numberController.text,
                  });
                });
                _saveContacts();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot make call')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contacts"),
        backgroundColor: Colors.teal,
      ),
      body: contacts.isEmpty
          ? Center(
        child: Text(
          "No contacts added yet.\nTap + to add one.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(Icons.person, color: Colors.teal),
              ),
              title: Text(
                contact['name']!,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(contact['number']!,
                  style: TextStyle(color: Colors.grey[700])),
              trailing: IconButton(
                icon: Icon(Icons.call, color: Colors.green),
                onPressed: () => _makeCall(contact['number']!),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, size: 28),
      ),
    );
  }
}
