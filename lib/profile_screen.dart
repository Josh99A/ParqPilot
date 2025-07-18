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

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          fullName = "User not logged in";
          phoneNumber = "-";
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          fullName = data['fullName'] ?? 'No Name';
          phoneNumber = data['phoneNumber'] ?? 'No Phone';
        });
      } else {
        setState(() {
          fullName = "No data found";
          phoneNumber = "-";
        });
      }
    } catch (e) {
      setState(() {
        fullName = "Error loading data";
        phoneNumber = "-";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 9, 77),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 165, 171, 235),
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Full Name", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 10),
                Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Phone Number", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 6),
            Text(phoneNumber, style: const TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
