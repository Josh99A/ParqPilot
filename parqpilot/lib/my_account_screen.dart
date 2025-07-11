import 'package:flutter/material.dart';
//import '../ParqPilot/lib/home_screen.dart';
import 'activity_screen.dart';
// import 'profile_screen.dart';

import 'profile_screen.dart';
import 'change_password_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  int _selectedIndex = 2;
  bool _isContactExpanded = false;
  bool _isAboutExpanded = false;

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ActivityScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: const Color.fromARGB(255, 165, 171, 235),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 2, 9, 77),
              Color.fromARGB(255, 15, 49, 243),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildListTile(title: "Profile", icon: Icons.person, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),
            const SizedBox(height: 40),
            _buildListTile(title: "Change Password", icon: Icons.lock, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            }),
            const SizedBox(height: 40),
            _buildExpandableTile(
              title: "Contact Us",
              icon: Icons.support_agent,
              isExpanded: _isContactExpanded,
              onTap: () => setState(() => _isContactExpanded = !_isContactExpanded),
              children: const [
                ListTile(
                  leading: Icon(Icons.message_rounded, color: Colors.white),
                  title: Text("WhatsApp", style: TextStyle(color: Colors.white)),
                ),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.white),
                  title: Text("Email", style: TextStyle(color: Colors.white)),
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.white),
                  title: Text("Call", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildExpandableTile(
              title: "About Us",
              icon: Icons.info,
              isExpanded: _isAboutExpanded,
              onTap: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "ParqPilot is a smart parking assistant designed to simplify your parking experience by offering real-time availability and historical activity tracking. Built with innovation, for your convenience.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue[900],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "My Account"),
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExpandableTile({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white,
        onExpansionChanged: (_) => onTap(),
        initiallyExpanded: isExpanded,
        title: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        children: children,
      ),
    );
  }
}
