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
      backgroundColor: Colors.deepPurple.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 50, backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null, child: user['photoUrl'] == null ? const Icon(Icons.person, size: 50) : null),
            const SizedBox(height: 10),
            Text(user['displayName'] ?? "Anonymous User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("${user['city'] ?? 'Unknown'}, ${user['state'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Fluttertoast.showToast(msg: "Connect request sent!"), child: const Text("Send Connect Request")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasLocationPermission) {
      return Scaffold(
        appBar: null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.white70),
              const SizedBox(height: 20),
              const Text("Location permission required\nto see nearby users", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _checkPermissions, child: const Text("Request Location Permission")),
              const SizedBox(height: 10),
              TextButton(onPressed: () async { await openAppSettings(); _checkPermissions(); }, child: const Text("Open Settings")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('isVerified', isEqualTo: true).where('isOnline', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['state'] == _userState && data['uid'] != FirebaseAuth.instance.currentUser!.uid;
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text("No one nearby right now\n(people with app open in your city/state)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
                  child: user['photoUrl'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user['displayName'] ?? "Anonymous User", style: const TextStyle(color: Colors.white)),
                subtitle: Text("${user['city'] ?? 'Unknown'}, ${user['state'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white70)),
                onTap: () => _showProfileModal(user),
                trailing: ElevatedButton(onPressed: () => Fluttertoast.showToast(msg: "Connect request sent!"), child: const Text("Connect")),
              );
            },
          );
        },
      ),
    );
  }
}