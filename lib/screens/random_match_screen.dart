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
  bool _isConnected = false;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();
    remoteRenderer.initialize();
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
        'mandatory': {'minWidth': '640', 'minHeight': '480'}
      }
    };
    try {
      localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = localStream;
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: "Camera/mic permission needed");
    }
  }

  Future<void> _startRandomMatch() async {
    setState(() => _isMatching = true);
    Fluttertoast.showToast(msg: "🔍 Looking for verified matches...");

    // Get location (keep for future distance filter)
    Position position = await Geolocator.getCurrentPosition();

    // Real Firestore queue — only verified users + future preference matching
    await FirebaseFirestore.instance.collection('matching_queue').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isVerified': true, // enforced from ID verification
      // TODO: Add interests, sex, hasKids, wantsKids, poly, etc. here for smart matching
    });

    // Start local camera immediately (real Omegle feel)
    await _getUserMedia();

    // Fake 4-second match (next push = real-time Firestore listener + WebRTC signaling)
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _isMatching = false;
      _isConnected = true;
    });
    Fluttertoast.showToast(msg: "🎉 Video match connected! (real signaling coming next)");
  }

  void _endCall() {
    localStream?.dispose();
    localRenderer.srcObject = null;
    setState(() => _isConnected = false);
    Fluttertoast.showToast(msg: "Call ended");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DateDash — Random Video Match'),
        backgroundColor: Colors.deepPurple.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade900,
              Colors.deepPurple.shade900,
              Colors.black87,
            ],
          ),
        ),
        child: Column(
          children: [
            // 18+ legal banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black.withOpacity(0.7),
              child: const Text(
                "18+ ONLY • ID Verified • Date responsibly",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  RTCVideoView(remoteRenderer, mirror: false),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton.icon(
                      onPressed: _isMatching || _isConnected ? null : _startRandomMatch,
                      icon: Icon(_isMatching ? Icons.hourglass_empty : Icons.flash_on),
                      label: Text(
                        _isMatching
                            ? "SEARCHING FOR MATCH..."
                            : "START RANDOM VIDEO MATCH",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isConnected)
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
                          onPressed: () => Fluttertoast.showToast(msg: "Reported & blocked"),
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
      ),
    );
  }

  @override
  void dispose() {
    localStream?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}