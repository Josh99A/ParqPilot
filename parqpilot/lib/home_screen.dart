import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'activity_screen.dart';
import 'my_account_screen.dart';
import 'map_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://parqpilot-2c029-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
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
                  if (snapshot.hasError) {
                    return const Center(child: Text('❌ Failed to load data'));
                  }

                  final data = snapshot.data?.snapshot.value;

                  if (kDebugMode) {
                    print('📦 Data from Firebase: $data');
                  }

                  if (data == null || data is! Map) {
                    return const Center(
                      child: Text(
                        '🚫 No parking slot data found.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    );
                  }

                  final slots = data.entries.toList();

                  if (slots.isEmpty) {
                    return const Center(
                      child: Text(
                        '🚘 No slots available in database.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slotKey = slots[index].key.toString();
                      final slotValue = slots[index].value;

                      final slotData = (slotValue as Map).map(
                        (key, value) => MapEntry(key.toString(), value),
                      );

                      final status =
                          slotData['status']?.toString().toLowerCase() ?? 'unknown';
                      final lastUpdated = slotData['lastUpdated'] ?? 'N/A';
                     // final lat = slotData['location']?['lat']?.toString() ?? 'N/A';
                      //final lng = slotData['location']?['lng']?.toString() ?? 'N/A';

                      Color statusColor =
                          status == 'free' ? Colors.green : Colors.red;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  slotKey,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  status == 'free'
                                      ? Icons.local_parking
                                      : Icons.block,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Last Updated: $lastUpdated',
                              style: const TextStyle(color: Colors.white70),
                            ),
                           // Text(
                             // 'Location: lat: $lat, lng: $lng',
                              //style: const TextStyle(color: Colors.white70),
                           // ),
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
