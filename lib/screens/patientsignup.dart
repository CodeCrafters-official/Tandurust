import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class SignUpPatientPage extends StatefulWidget {
  @override
  _SignUpPatientPageState createState() => _SignUpPatientPageState();
}

class _SignUpPatientPageState extends State<SignUpPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // AES Encryption setup (optional)
  final key = encrypt.Key.fromUtf8('16charslongkey!!'); // 16/24/32 chars
  final iv = encrypt.IV.fromLength(16);
  late encrypt.Encrypter encrypter;

  @override
  void initState() {
    super.initState();
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  String encryptText(String plainText) {
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  Future<void> signupPatient() async {
    if (!_formKey.currentState!.validate()) return;

    String encryptedPhone = encryptText(_phoneController.text.trim());
    String encryptedAddress = encryptText(_addressController.text.trim());

    var data = {
      "username": _nameController.text.trim(),
      "age": int.tryParse(_ageController.text.trim()) ?? 0,
      "gender": _genderController.text.trim(),
      "password": encryptedPhone,
      "address": encryptedAddress,
    };

    var url = Uri.parse("https://ddc84add1485.ngrok-free.app/patients/signup"); // Replace with Ngrok URL if testing on phone
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Patient signup successful!")),
      );
      _formKey.currentState!.reset();
    } else {
      var error = jsonDecode(response.body)['error'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: Image.asset('assets/logo.png'),
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter name" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: "Age",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? "Enter age" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _genderController,
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter gender" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: signupPatient,
                      child: const Text("Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
