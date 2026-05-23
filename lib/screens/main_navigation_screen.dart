import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'random_match_screen.dart'; // your existing match screen

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // default to Match tab

  final List<Widget> _screens = [
    const Center(child: Text('Home Screen - Coming Soon', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Friends Screen - Coming Soon', style: TextStyle(fontSize: 24))),
    const RandomMatchScreen(),           // ← your full video match screen
    const Center(child: Text('Chat Screen - Coming Soon', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Filter Screen (Premium) - Coming Soon', style: TextStyle(fontSize: 24))),
  ];

  void _showProfileDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile header
            const CircleAvatar(radius: 40, backgroundColor: Colors.pinkAccent),
            const SizedBox(height: 10),
            const Text("Your Name", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Verified User", style: TextStyle(color: Colors.white70)),
            const Divider(color: Colors.white24, height: 30),
            // Menu items (you can add more later)
            ListTile(leading: const Icon(Icons.settings, color: Colors.white), title: const Text("Settings", style: TextStyle(color: Colors.white)), onTap: () {}),
            const Spacer(),
            // Logout at bottom
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DateDash'),
        backgroundColor: Colors.deepPurple.shade900,
        actions: [
          // Profile icon (circle) top right
          GestureDetector(
            onTap: _showProfileDrawer,
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pinkAccent,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.deepPurple.shade900,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.filter_list), label: 'Filter'),
        ],
      ),
    );
  }
}