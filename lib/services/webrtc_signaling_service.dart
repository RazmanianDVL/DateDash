import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Create a new call/match room
  Future<String> createCallRoom() async {
    final roomRef = await _firestore.collection('calls').add({
      'callerId': _currentUserId,
      'calleeId': null,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return roomRef.id;
  }

  // Listen for incoming calls
  Stream<DocumentSnapshot> listenForIncomingCalls() {
    return _firestore.collection('calls')
        .where('calleeId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs.first);
  }

  // TODO: Full signaling logic (offer, answer, ICE candidates) will be expanded in next phase
}
