import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/webrtc_signaling_service.dart';   // ← new import

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
  RTCPeerConnection? _peerConnection;
  String? _currentRoomId;

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();
    remoteRenderer.initialize();
  }

  Future<void> _getUserMedia() async {
    final constraints = {'audio': true, 'video': {'facingMode': 'user'}};
    localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = localStream;
    setState(() {});
  }

  Future<void> _startRandomMatch() async {
    bool? consent = await _showConsentDialog();
    if (consent != true) return;

    setState(() => _isMatching = true);
    Fluttertoast.showToast(msg: "🔍 Looking for matches...");

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Add to queue
    final queueRef = await FirebaseFirestore.instance.collection('matching_queue').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isVerified': true,
    });

    await _getUserMedia();

    // TODO: Real matching logic (for now we simulate a room)
    // In production this would find another user and create a shared roomId
    _currentRoomId = 'room-${DateTime.now().millisecondsSinceEpoch}';

    _peerConnection = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]});

    WebRTCSignalingService signaling = WebRTCSignalingService(
      roomId: _currentRoomId!,
      currentUserId: FirebaseAuth.instance.currentUser!.uid,
    );

    // Send offer
    await signaling.createOffer(_peerConnection!);
    signaling.listenForRemoteAnswer(_peerConnection!);
    signaling.listenForIceCandidates(_peerConnection!);

    // Fake match for testing (replace with real queue listener later)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isMatching = false;
      _isConnected = true;
    });
    Fluttertoast.showToast(msg: "🎉 Connected! Video should now be live.");
  }

  Future<bool?> _showConsentDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text("18+ ONLY", style: TextStyle(color: Colors.white)),
        content: const Text("Date responsibly.\nAll users are ID verified.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("I am 18+")),
        ],
      ),
    );
  }

  void _endCall() {
    localStream?.dispose();
    _peerConnection?.close();
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    setState(() => _isConnected = false);
    Fluttertoast.showToast(msg: "Call ended");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DateDash — Random Video Match'), backgroundColor: Colors.deepPurple.shade900),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade900, Colors.deepPurple.shade900, Colors.black87],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black.withOpacity(0.7),
              child: const Center(child: Text("18+ ONLY • ID Verified • Date responsibly", style: TextStyle(color: Colors.white70, fontSize: 13))),
            ),
            Expanded(
              child: Stack(
                children: [
                  RTCVideoView(remoteRenderer, mirror: false), // main call window
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
                      child: RTCVideoView(localRenderer, mirror: true), // selfie window
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
                      label: Text(_isMatching ? "SEARCHING..." : "MATCH!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    ),
                  ),
                  if (_isConnected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(onPressed: _endCall, icon: const Icon(Icons.call_end), label: const Text("End"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(onPressed: () => Fluttertoast.showToast(msg: "Reported"), icon: const Icon(Icons.report), label: const Text("Report")),
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
    _peerConnection?.close();
    super.dispose();
  }
}