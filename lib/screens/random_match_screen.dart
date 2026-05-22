import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RandomMatchScreen extends StatefulWidget {
  const RandomMatchScreen({super.key});

  @override
  State<RandomMatchScreen> createState() => _RandomMatchScreenState();
}

class _RandomMatchScreenState extends State<RandomMatchScreen> {
  bool _isMatching = false;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();
    remoteRenderer.initialize();
  }

  Future<void> _startRandomMatch() async {
    setState(() => _isMatching = true);
    Fluttertoast.showToast(msg: "🔍 Looking for nearby verified users...");

    // Get current location
    Position position = await Geolocator.getCurrentPosition();

    // Simple Firestore queue (real matching in production would use Cloud Functions + WebRTC signaling)
    await FirebaseFirestore.instance.collection('matching_queue').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Fake delay + connection (replace with real signaling later)
    await Future.delayed(const Duration(seconds: 4));

    setState(() => _isMatching = false);
    Fluttertoast.showToast(msg: "🎉 Connected to a random verified user nearby!");
  }

  void _endCall() {
    Fluttertoast.showToast(msg: "Call ended");
    // In full version this would close the WebRTC peer connection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DateDash — Random Match')),
      body: Column(
        children: [
          // Video area
          Expanded(
            child: Stack(
              children: [
                // Remote video (the other person)
                RTCVideoView(remoteRenderer, mirror: false),
                // Local video (your camera) - picture-in-picture
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    width: 130,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.pinkAccent, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RTCVideoView(localRenderer, mirror: true),
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton.icon(
                    onPressed: _isMatching ? null : _startRandomMatch,
                    icon: Icon(_isMatching ? Icons.hourglass_empty : Icons.flash_on),
                    label: Text(
                      _isMatching ? "SEARCHING FOR MATCH..." : "START RANDOM MATCH",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: const Text("End Call"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Fluttertoast.showToast(msg: "Reported & blocked");
                      },
                      icon: const Icon(Icons.report, color: Colors.white),
                      label: const Text("Report / Block"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}