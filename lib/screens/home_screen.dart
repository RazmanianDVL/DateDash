import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String? _userCity = "Tulsa";
  String? _userState = "OK";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    setState(() {
      _hasLocationPermission = status.isGranted;
      _isLoading = false;
    });
    if (status.isGranted) {
      await _saveUserLocation();
    }
  }

  Future<void> _saveUserLocation() async {
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'city': _userCity,
      'state': _userState,
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  void _showProfileModal(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Color(0xFF2C0A4D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
                child: user['photoUrl'] == null ? const Icon(Icons.person, size: 70, color: Colors.white70) : null,
              ),
              const SizedBox(height: 16),
              Text(
                user['displayName'] ?? "Anonymous User",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "${user['city'] ?? 'Unknown'}, ${user['state'] ?? 'Unknown'}",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Fluttertoast.showToast(msg: "Connect request sent!");
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Send Connect Request"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
      );
    }

    if (!_hasLocationPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 90, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                "Location permission required\nto see nearby users",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text("Grant Location Permission"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  _checkPermissions();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B1B5E), Color(0xFF2C0A4D), Colors.black87],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('isVerified', isEqualTo: true)
              .where('isOnline', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
            }

            final users = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['state'] == _userState && data['uid'] != FirebaseAuth.instance.currentUser!.uid;
            }).toList();

            if (users.isEmpty) {
              return const Center(
                child: Text(
                  "No one nearby right now\n(people with the app open in your area)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white.withOpacity(0.1),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
                      child: user['photoUrl'] == null ? const Icon(Icons.person, size: 35, color: Colors.white70) : null,
                    ),
                    title: Text(
                      user['displayName'] ?? "Anonymous User",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      "${user['city'] ?? 'Unknown'}, ${user['state'] ?? 'Unknown'}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => Fluttertoast.showToast(msg: "Connect request sent!"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Connect"),
                    ),
                    onTap: () => _showProfileModal(user),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}