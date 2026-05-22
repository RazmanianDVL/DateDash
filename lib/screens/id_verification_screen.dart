import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';   // ← this import is correct now

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
        if (snapshot.hasData && snapshot.data!.exists && snapshot.data!['isVerified'] == true) {
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
      if (idPhoto == null) throw Exception('ID photo required');

      final selfie = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (selfie == null) throw Exception('Selfie required');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "ID Verified Successfully! 🎉");
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID Verification (Required)')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 120, color: Colors.pinkAccent),
            const SizedBox(height: 30),
            const Text(
              'Verify Your Identity',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Take a clear photo of your government ID\nthen record a live selfie',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.pinkAccent)
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _verifyID,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('START VERIFICATION', style: TextStyle(fontSize: 18)),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text(
              'This is required for safety.\nYour data is encrypted and never shared.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}