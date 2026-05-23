import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'home_screen.dart';

class IDVerificationGate extends StatelessWidget {
  const IDVerificationGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists && 
            (snapshot.data!['verificationStatus'] == 'approved' || snapshot.data!['isVerified'] == true)) {
          return const HomeScreen();
        }
        return const IDVerificationScreen();
      },
    );
  }
}

class IDVerificationScreen extends StatefulWidget {
  const IDVerificationScreen({super.key});

  @override
  State<IDVerificationScreen> createState() => _IDVerificationScreenState();
}

class _IDVerificationScreenState extends State<IDVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _verifyID() async {
    setState(() => _isLoading = true);

    try {
      final idPhoto = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (idPhoto == null) throw Exception('ID photo is required');

      final selfie = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (selfie == null) throw Exception('Selfie is required');

      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      // Upload ID photo
      final idRef = FirebaseStorage.instance
          .ref('users/$uid/id_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await idRef.putFile(File(idPhoto.path));
      final idUrl = await idRef.getDownloadURL();

      // Upload Selfie
      final selfieRef = FirebaseStorage.instance
          .ref('users/$uid/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await selfieRef.putFile(File(selfie.path));
      final selfieUrl = await selfieRef.getDownloadURL();

      // Update user document with pending status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'idPhotoUrl': idUrl,
        'selfieUrl': selfieUrl,
        'verificationStatus': 'pending',
        'verifiedAt': null,
        'isVerified': false,  // Keep for backward compatibility
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "ID & Selfie uploaded! Verification pending approval.", 
        backgroundColor: Colors.orange);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your verification is under review. You will be notified soon.')),
        );
        // Optionally navigate back or to waiting screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0033), Color(0xFF2C0A4D), Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user, size: 140, color: Colors.pinkAccent),
                const SizedBox(height: 48),

                const Text(
                  'Verify Your Identity',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Take a clear photo of your government ID\nand a live selfie for face match',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
                ),

                const SizedBox(height: 80),

                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.pinkAccent)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 66,
                    child: ElevatedButton(
                      onPressed: _verifyID,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 12,
                      ),
                      child: const Text(
                        'START VERIFICATION',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 48),

                const Text(
                  'This is required for safety.\nYour data is encrypted and never shared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}