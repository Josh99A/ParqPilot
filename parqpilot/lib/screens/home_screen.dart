import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'activity_screen.dart';
import 'my_account_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ✅ Correctly point to the database in asia-southeast1 region
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // (
  //   databaseURL: 'https://parqpilot-2c029-default-rtdb.asia-southeast1.firebasedatabase.app/',
  // );

  late final DatabaseReference _parkingRef;

  @override
  void initState() {
    super.initState();
    _parkingRef = _database.ref('MakerereCocisParking_lot');
  }

  void _onNavBarTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyAccountScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          },
        ),
        title: const Text("Available Parking Slots"),
        backgroundColor: const Color(0xFF000428),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000428), Color(0xFF004e92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _parkingRef.onValue,
                builder: (context, snapshot) {
                  print('📡 Firebase snapshot: ${snapshot.data?.snapshot.value}');

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final value = snapshot.data!.snapshot.value;
                  if (value is! Map) {
                    return const Center(child: Text('No valid data found.'));
                  }

                  final data = Map<String, dynamic>.from(value);
                  final slots = data.entries
                      .where((e) => e.key.toString().startsWith('Slot'))
                      .toList();

                  if (slots.isEmpty) {
                    return const Center(child: Text('No parking slots found.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slotKey = slots[index].key.toString();
                      final slotDataRaw = slots[index].value;

                      final slotData = slotDataRaw is Map
                          ? Map<String, dynamic>.from(slotDataRaw)
                          : {};

                      String status = slotData['status']?.toString() ?? 'unknown';

                      // Fix typo if exists in Firebase
                      if (status == 'occuppied') status = 'occupied';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              slotKey,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            Icon(
                              status == 'free' ? Icons.local_parking : Icons.block,
                              color: Colors.white,
                              size: 28,
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
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Account'),
        ],
      ),
    );
  }
}
