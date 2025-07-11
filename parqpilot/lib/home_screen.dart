import 'package:flutter/material.dart';
import 'activity_screen.dart';
import 'my_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavBarTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ActivityScreen()),
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000428),
              Color(0xFF004e92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Available Parking Slots",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: List.generate(6, (index) {
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
                          'Slot ${String.fromCharCode(65 + index)}${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const Icon(Icons.local_parking, color: Colors.white, size: 28),
                      ],
                    ),
                  );
                }),
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
