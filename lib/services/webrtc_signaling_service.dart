import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCSignalingService {
  final String roomId;
  final String currentUserId;

  WebRTCSignalingService({required this.roomId, required this.currentUserId});

  Future<void> createOffer(RTCPeerConnection pc) async {
    RTCSessionDescription offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(roomId)
        .set({'offer': offer.toMap(), 'callerId': currentUserId}, SetOptions(merge: true));
  }

  Future<void> createAnswer(RTCPeerConnection pc) async {
    RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(roomId)
        .update({'answer': answer.toMap()});
  }

  void listenForRemoteOffer(RTCPeerConnection pc, Function onOfferReceived) {
    FirebaseFirestore.instance.collection('calls').doc(roomId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['offer'] != null && data['callerId'] != currentUserId) {
        onOfferReceived(data['offer']);
      }
    });
  }

  void listenForRemoteAnswer(RTCPeerConnection pc) {
    FirebaseFirestore.instance.collection('calls').doc(roomId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['answer'] != null) {
        pc.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['answer']['type']));
      }
    });
  }

  void addIceCandidate(RTCIceCandidate candidate) {
    FirebaseFirestore.instance.collection('calls').doc(roomId).collection('iceCandidates').add({
      'candidate': candidate.toMap(),
      'senderId': currentUserId,
    });
  }

  void listenForIceCandidates(RTCPeerConnection pc) {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(roomId)
        .collection('iceCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data()!;
          if (data['senderId'] != currentUserId) {
            pc.addCandidate(RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ));
          }
        }
      }
    });
  }
}