import 'package:flutter/material.dart';
import 'package:parqpilot/home_screen.dart';
//import 'my_account_screen.dart'; // Make sure this import matches your file structure

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Full Name",
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person, color: Colors.white),
                SizedBox(width: 10),
                Text("Vivian Komuhendo",
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
            SizedBox(height: 30),
            Text("Phone Number",
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 6),
            Text("+256 701 234567",
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
