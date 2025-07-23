import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = "Loading...";
  String phoneNumber = "Loading...";
  String email = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? "No Email";

      if (uid == null) {
        setState(() {
          fullName = "User not logged in";
          phoneNumber = "-";
          email = userEmail;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          fullName = data['fullName'] ?? 'No Name';
          phoneNumber = data['phoneNumber'] ?? 'No Phone';
          email = userEmail;
        });
      } else {
        setState(() {
          fullName = "No data found";
          phoneNumber = "-";
          email = userEmail;
        });
      }
    } catch (e) {
      setState(() {
        fullName = "Error loading data";
        phoneNumber = "-";
        email = "N/A";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 9, 77),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 165, 171, 235),
        title: const Text("My Profile"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Color.fromARGB(255, 2, 9, 77)),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildProfileRow("Full Name", fullName),
                      const Divider(color: Colors.white24),
                      buildProfileRow("Phone Number", phoneNumber),
                      const Divider(color: Colors.white24),
                      buildProfileRow("Email", email),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
