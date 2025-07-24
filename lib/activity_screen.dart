import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:parqpilot/home_screen.dart';
import 'my_account_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _selectedIndex = 1;

  void _onNavBarTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyAccountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGradient = LinearGradient(
      colors: [Color.fromARGB(255, 2, 9, 77), Color.fromARGB(255, 8, 15, 99)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    const textColor = Colors.white;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: backgroundGradient),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking History',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('history')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No parking history found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final historyDocs = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: historyDocs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white24),
                    itemBuilder: (context, index) {
                      final data =
                          historyDocs[index].data() as Map<String, dynamic>;

                      final isAvailable = data['status'] == 'Available';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Slot: ${data['slot']}',
                                  style: const TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isAvailable
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: isAvailable
                                          ? Colors.green
                                          : Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      data['status'],
                                      style: TextStyle(
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['date'],
                                  style: const TextStyle(color: textColor),
                                ),
                                Text(
                                  data['time'],
                                  style: const TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 2, 9, 77),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Account',
          ),
        ],
      ),
    );
  }
}
