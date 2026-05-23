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
  bool _isInitialized = false;
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

  Offset _previewPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    localRenderer.initialize();
    remoteRenderer.initialize();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    final locStatus = await Permission.locationWhenInUse.status;

    final hasAll = cameraStatus.isGranted && micStatus.isGranted && locStatus.isGranted;

    setState(() {
      _hasPermissions = hasAll;
      _isInitialized = true;
    });

    if (hasAll) await _startLivePreview();
  }

  Future<void> _requestPermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    final loc = await Permission.locationWhenInUse.request();

    final hasAll = camera.isGranted && mic.isGranted && loc.isGranted;
    setState(() => _hasPermissions = hasAll);

    if (hasAll) await _startLivePreview();
  }

  Future<void> _startLivePreview() async {
    try {
      final constraints = {'audio': true, 'video': {'facingMode': 'user'}};
      localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = localStream;
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: "Could not access camera");
    }
  }

  // ... (your existing matching logic stays the same - _startRandomMatch, _showConsentDialog, _endCall, _skipCall)

  Future<void> _startRandomMatch() async { /* your existing code */ }
  Future<bool?> _showConsentDialog() async { /* your existing code */ }
  void _endCall() { /* your existing code */ }
  void _skipCall() { /* your existing code */ }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final previewWidth = screenWidth * 0.38;

    if (_previewPosition == Offset.zero) {
      final size = MediaQuery.of(context).size;
      _previewPosition = Offset(size.width - previewWidth - 20, size.height * 0.55);
    }

    String timerText = "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}";

    if (_isInitialized && !_hasPermissions) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.white70),
              const SizedBox(height: 20),
              const Text("Camera, microphone & location permissions required", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _requestPermissions, child: const Text("Grant Permissions")),
              const SizedBox(height: 10),
              TextButton(onPressed: () async { await openAppSettings(); _checkPermissionsAndInitialize(); }, child: const Text("Open Settings")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B1B5E), Color(0xFF2C0A4D), Colors.black87],
          ),
        ),
        child: Stack(
          children: [
            // 18+ banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Text("18+ ONLY • ID Verified • Date responsibly", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ),
            ),

            // Remote video (full screen)
            RTCVideoView(remoteRenderer, mirror: false),

            // Draggable local preview with modern neon border
            Positioned(
              left: _previewPosition.dx,
              top: _previewPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final size = MediaQuery.of(context).size;
                    _previewPosition += details.delta;
                    _previewPosition = Offset(
                      _previewPosition.dx.clamp(10.0, size.width - previewWidth - 10),
                      _previewPosition.dy.clamp(60.0, size.height - 250.0),
                    );
                  });
                },
                child: SizedBox(
                  width: previewWidth,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pinkAccent, width: 6),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.pinkAccent.withOpacity(0.5), blurRadius: 25, spreadRadius: 4),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: RTCVideoView(localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls with modern look
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (_isConnected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(timerText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 20),
                        if (_showSkipButton)
                          ElevatedButton.icon(onPressed: _skipCall, icon: const Icon(Icons.skip_next), label: const Text("Skip"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
                      ],
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton.icon(
                      onPressed: _isMatching || _isConnected ? null : _startRandomMatch,
                      icon: Icon(_isMatching ? Icons.hourglass_empty : Icons.flash_on, size: 28),
                      label: Text(_isMatching ? "SEARCHING NEARBY..." : "MATCH NEARBY!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
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