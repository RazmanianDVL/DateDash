import 'package:flutter/material.dart';
import 'package:datedash/screens/home_screen.dart';
import 'package:datedash/screens/random_match_screen.dart';
import 'package:datedash/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Default to Match tab

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(
      child: Text(
        'Friends Screen - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
    const RandomMatchScreen(),
    const Center(
      child: Text(
        'Chat Screen - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
    const Center(
      child: Text(
        'Filter Screen - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DateDash'),
        backgroundColor: Colors.deepPurple.shade900,
        actions: [
          // Pink profile icon - now opens ProfileScreen
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pinkAccent,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.deepPurple.shade900,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Filter',
          ),
        ],
      ),
    );
  }
}