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
  bool _hasLocationPermission = false;
  String? _userCity;
  String? _userState;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndLoadNearby();
  }

  Future<void> _checkLocationPermissionAndLoadNearby() async {
    final status = await Permission.locationWhenInUse.request();
    setState(() => _hasLocationPermission = status.isGranted);

    if (!status.isGranted) {
      Fluttertoast.showToast(msg: "Location permission needed to see nearby users");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // For now we use Tulsa/OK for testing — later we'll add real reverse geocoding
    setState(() {
      _userCity = "Tulsa";
      _userState = "OK";
    });

    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'city': _userCity,
      'state': _userState,
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocationPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Users'), backgroundColor: Colors.deepPurple.shade900),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Location permission required to see nearby users", style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  _checkLocationPermissionAndLoadNearby();
                },
                child: const Text("Enable Location Permissions"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Users'), backgroundColor: Colors.deepPurple.shade900),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isVerified', isEqualTo: true)
            .where('isOnline', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['state'] == _userState && data['uid'] != FirebaseAuth.instance.currentUser!.uid;
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text("No one nearby right now\n(people with app open in your city/state)", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.pinkAccent, child: const Icon(Icons.person, color: Colors.white)),
                title: Text(user['displayName'] ?? "Anonymous User", style: const TextStyle(color: Colors.white)),
                subtitle: Text("${user['city'] ?? 'Unknown'}, ${user['state'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  onPressed: () => Fluttertoast.showToast(msg: "Connect request sent!"),
                  child: const Text("Connect"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}