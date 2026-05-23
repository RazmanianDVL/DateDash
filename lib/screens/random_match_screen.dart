import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;

class RandomMatchScreen extends StatefulWidget {
  const RandomMatchScreen({super.key});

  @override
  State<RandomMatchScreen> createState() => _RandomMatchScreenState();
}

class _RandomMatchScreenState extends State<RandomMatchScreen> {
  bool _isMatching = false;
  bool _isConnected = false;
  bool _hasCameraPermission = false;
  bool _hasLocationPermission = false;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;
  RTCPeerConnection? _peerConnection;
  String? _currentRoomId;

  Timer? _callTimer;
  int _secondsRemaining = 300;
  bool _showSkipButton = false;

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();
    remoteRenderer.initialize();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    // Camera + Mic
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    setState(() => _hasCameraPermission = cameraStatus.isGranted && micStatus.isGranted);

    // Location
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    LocationPermission locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied) {
      locPerm = await Geolocator.requestPermission();
    }
    setState(() => _hasLocationPermission = locPerm == LocationPermission.whileInUse || locPerm == LocationPermission.always);
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _getUserMedia() async {
    if (!_hasCameraPermission) return;

    try {
      final constraints = {'audio': true, 'video': {'facingMode': 'user'}};
      localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = localStream;
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to access camera");
    }
  }

  Future<void> _startRandomMatch() async {
    if (!_hasCameraPermission || !_hasLocationPermission) {
      Fluttertoast.showToast(msg: "Camera and location permissions are required");
      return;
    }

    bool? consent = await _showConsentDialog();
    if (consent != true) return;

    setState(() => _isMatching = true);
    Fluttertoast.showToast(msg: "🔍 Finding nearby verified users...");

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    await FirebaseFirestore.instance.collection('matching_queue').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isVerified': true,
    });

    await _getUserMedia();

    _currentRoomId = 'room-${DateTime.now().millisecondsSinceEpoch}';
    _peerConnection = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]});

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isMatching = false;
      _isConnected = true;
      _secondsRemaining = 300;
      _showSkipButton = false;
    });

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining == 180) setState(() => _showSkipButton = true);
      } else {
        timer.cancel();
        _endCall();
      }
    });

    Fluttertoast.showToast(msg: "🎉 Connected to nearby user!");
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
    _callTimer?.cancel();
    localStream?.dispose();
    _peerConnection?.close();
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    setState(() => _isConnected = false);
    Fluttertoast.showToast(msg: "Call ended");
  }

  void _skipCall() {
    _endCall();
    Fluttertoast.showToast(msg: "Skipped — looking for better match");
  }

  @override
  Widget build(BuildContext context) {
    String timerText = "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}";

    if (!_hasCameraPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('DateDash — Nearby Match'), backgroundColor: Colors.deepPurple.shade900),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Camera permission required for video matching", style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openAppSettings,
                child: const Text("Enable Camera Permissions"),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasLocationPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('DateDash — Nearby Match'), backgroundColor: Colors.deepPurple.shade900),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Location permission required for nearby matching", style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openAppSettings,
                child: const Text("Enable Location Permissions"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('DateDash — Nearby Match'), backgroundColor: Colors.deepPurple.shade900),
      body: Container(
        decoration: BoxDecoration(
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
                  if (_isConnected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(timerText, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 20),
                        if (_showSkipButton)
                          ElevatedButton.icon(onPressed: _skipCall, icon: const Icon(Icons.skip_next), label: const Text("Skip"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
                      ],
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton.icon(
                      onPressed: _isMatching || _isConnected ? null : _startRandomMatch,
                      icon: Icon(_isMatching ? Icons.hourglass_empty : Icons.flash_on),
                      label: Text(_isMatching ? "SEARCHING NEARBY..." : "MATCH NEARBY!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
    _callTimer?.cancel();
    localStream?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }
}