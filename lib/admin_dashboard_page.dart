import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();

  String emailGenere = "";
  String passwordGenere = "";
  bool loading = false;

  String _randomPassword(int length) {
    const chars =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final rnd = Random();
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _createStudent() async {
    setState(() => loading = true);

    final first = firstNameCtrl.text.trim().toLowerCase();
    final last = lastNameCtrl.text.trim().toLowerCase();

    final email = "$first.$last@eleve.com";
    final password = _randomPassword(8);

    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        emailGenere = email;
        passwordGenere = password;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: firstNameCtrl,
              decoration: const InputDecoration(labelText: "Prénom"),
            ),
            TextField(
              controller: lastNameCtrl,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _createStudent,
              child: const Text("Générer ID élève"),
            ),
            const SizedBox(height: 30),
            if (emailGenere.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email : $emailGenere",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Mot de passe : $passwordGenere",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
