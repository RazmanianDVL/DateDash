// Updated Profile Screen with full preference fields for DateDash
// Backend Grok - Preference matching ready

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Add all preference fields here
  String bio = '';
  List<String> interests = [];
  List<String> lookingFor = [];
  int ageMin = 18;
  int ageMax = 99;
  bool hasKids = false;
  bool wantsKids = false;
  bool polyAmorous = false;
  bool divorced = false;
  bool newlySingle = false;
  // ... other fields

  Future<void> saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'bio': bio,
      'interests': interests,
      'lookingFor': lookingFor,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'hasKids': hasKids,
      'wantsKids': wantsKids,
      'polyAmorous': polyAmorous,
      'divorced': divorced,
      'newlySingle': newlySingle,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Add UI for all preference fields (multi-select interests, toggles, etc.)
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}