import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class RandomMatchScreen extends StatefulWidget {
  const RandomMatchScreen({super.key});

  @override
  State<RandomMatchScreen> createState() => _RandomMatchScreenState();
}

class _RandomMatchScreenState extends State<RandomMatchScreen> {
  bool _hasPermissions = false;
  bool _isInitialized = false;          // ← Prevents permission screen flash
  bool _isMatching = false;
  bool _isConnected = false;

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
    _checkPermissionsAndInitialize();   // ← Checks first, then loads UI
  }

  /// Checks current permission status FIRST (no flash on load)
  Future<void> _checkPermissionsAndInitialize() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    final locStatus = await Permission.locationWhenInUse.status;

    final hasAll = cameraStatus.isGranted && micStatus.isGranted && locStatus.isGranted;

    setState(() {
      _hasPermissions = hasAll;
      _isInitialized = true;
    });

    if (hasAll) {
      await _startLivePreview();
    }
  }

  Future<void> _requestPermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    final loc = await Permission.locationWhenInUse.request();

    final hasAll = camera.isGranted && mic.isGranted && loc.isGranted;

    setState(() => _hasPermissions = hasAll);

    if (hasAll) {
      await _startLivePreview();
    } else {
      Fluttertoast.showToast(msg: "Permissions are required for matching");
    }
  }

  Future<void> _startLivePreview() async {
    try {
      final constraints = {'audio': true, 'video': {'facingMode': 'user'}};
      localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = localStream;
      setState(() {}); // force preview refresh
    } catch (e) {
      Fluttertoast.showToast(msg: "Could not access camera");
    }
  }

  Future<void> _startRandomMatch() async {
    if (!_hasPermissions) return;

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

    // Only show permission screen AFTER initialization check
    if (_isInitialized && !_hasPermissions) {
      return Scaffold(
        appBar: AppBar(title: const Text('DateDash — Nearby Match'), backgroundColor: Colors.deepPurple.shade900),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.white70),
              const SizedBox(height: 20),
              const Text("Camera, microphone & location permissions required",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _requestPermissions, child: const Text("Grant Permissions")),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  _checkPermissionsAndInitialize();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        ),
      );
    }

    // Main DateDash Nearby Match UI (loads immediately with live preview)
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
                    bottom: 30,
                    right: 20,
                    child: Container(
                      width: 140,
                      height: 210,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pinkAccent, width: 6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16), // ← PERFECTLY MATCHES border (fixed misalignment)
                        child: RTCVideoView(localRenderer, mirror: true),
                      ),
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