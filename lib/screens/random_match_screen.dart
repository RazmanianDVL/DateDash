import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  // Draggable preview
  Offset _previewPosition = Offset(0, 0);
  double _previewWidth = 155.w; // responsive base size

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

      localRenderer.onResize = (int width, int height) {
        if (width > 0 && height > 0) {
          setState(() {}); // refresh for cover fit
        }
      };

      setState(() {}); // force preview refresh
    } catch (e) {
      Fluttertoast.showToast(msg: "Could not access camera");
    }
  }

  // ... (rest of your matching logic stays exactly the same - _startRandomMatch, consent dialog, endCall, etc.)

  Future<void> _startRandomMatch() async { /* unchanged from previous version */ }
  Future<bool?> _showConsentDialog() async { /* unchanged */ }
  void _endCall() { /* unchanged */ }
  void _skipCall() { /* unchanged */ }

  @override
  Widget build(BuildContext context) {
    // Responsive preview default position (bottom-right)
    if (_previewPosition == Offset.zero) {
      final size = MediaQuery.of(context).size;
      _previewPosition = Offset(size.width - _previewWidth - 20.w, size.height * 0.55);
    }

    String timerText = "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}";

    if (_isInitialized && !_hasPermissions) {
      return Scaffold(/* permission screen unchanged */);
    }

    return Scaffold(
      appBar: null, // ← Header space completely removed
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.pink.shade900, Colors.deepPurple.shade900, Colors.black87],
            ),
          ),
          child: Stack(
            children: [
              // Top banner (18+ ONLY)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Text(
                      "18+ ONLY • ID Verified • Date responsibly",
                      style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                    ),
                  ),
                ),
              ),

              // Remote video (full screen background)
              RTCVideoView(remoteRenderer, mirror: false),

              // Draggable local preview with perfect pink neon border
              Positioned(
                left: _previewPosition.dx,
                top: _previewPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final size = MediaQuery.of(context).size;
                      _previewPosition += details.delta;
                      // Clamp to screen edges
                      _previewPosition = Offset(
                        _previewPosition.dx.clamp(10.w, size.width - _previewWidth - 10.w),
                        _previewPosition.dy.clamp(60.h, size.height - 220.h),
                      );
                    });
                  },
                  child: SizedBox(
                    width: _previewWidth,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.pinkAccent, width: 6.w),
                          borderRadius: BorderRadius.circular(18.r),
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
                          borderRadius: BorderRadius.circular(18.r),
                          child: RTCVideoView(
                            localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom controls (MATCH NEARBY button + timer)
              Positioned(
                bottom: 20.h,
                left: 20.w,
                right: 20.w,
                child: Column(
                  children: [
                    if (_isConnected)
                      Row(/* timer + skip button unchanged */),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 70.h,
                      child: ElevatedButton.icon(/* MATCH NEARBY button unchanged */),
                    ),
                    if (_isConnected)
                      Row(/* End + Report buttons unchanged */),
                  ],
                ),
              ),
            ],
          ),
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