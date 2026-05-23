import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  List<String> photoUrls = [];
  String? profilePicUrl;
  String relationshipStatus = 'Single';
  String bio = '';
  List<String> hobbies = [];
  Position? currentPosition;

  final List<String> relationshipOptions = [
    'Single', 'Married', 'Open Relationship', 'Divorced', 'Situationship'
  ];

  final List<String> allHobbies = [
    'Hiking', 'Gym', 'Travel', 'Reading', 'Gaming', 'Cooking', 'Music', 'Dancing',
    'Movies', 'Sports', 'Photography', 'Art', 'Yoga', 'Wine tasting', 'Concerts'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _getCurrentLocation();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        photoUrls = List<String>.from(data['photoUrls'] ?? []);
        profilePicUrl = data['profilePicUrl'];
        relationshipStatus = data['relationshipStatus'] ?? 'Single';
        bio = data['bio'] ?? '';
        hobbies = List<String>.from(data['hobbies'] ?? []);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() => currentPosition = position);
  }

  Future<void> _pickAndUploadPhoto() async {
    if (photoUrls.length >= 10) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Crop/zoom editor
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [AndroidUiSettings(toolbarTitle: 'Edit Photo')],
    );

    if (cropped == null) return;

    // Upload to Firebase Storage
    final ref = _storage.ref().child('profile_photos/${user!.uid}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(cropped.path));
    final url = await ref.getDownloadURL();

    setState(() {
      photoUrls.add(url);
    });
    _saveProfile();
  }

  void _setAsProfilePic(String url) {
    setState(() => profilePicUrl = url);
    _saveProfile();
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    await _firestore.collection('users').doc(user!.uid).set({
      'photoUrls': photoUrls,
      'profilePicUrl': profilePicUrl,
      'relationshipStatus': relationshipStatus,
      'bio': bio,
      'hobbies': hobbies,
      'latitude': currentPosition?.latitude,
      'longitude': currentPosition?.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.deepPurple.shade900),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Photo grid (up to 10)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photoUrls.length + 1,
              itemBuilder: (context, index) {
                if (index == photoUrls.length) {
                  return GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.pinkAccent), borderRadius: BorderRadius.circular(12.r)),
                      child: const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.pinkAccent)),
                    ),
                  );
                }
                final url = photoUrls[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _setAsProfilePic(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    ),
                    if (profilePicUrl == url)
                      const Positioned(top: 8, right: 8, child: Icon(Icons.star, color: Colors.amber)),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Relationship Status
            DropdownButtonFormField<String>(
              value: relationshipStatus,
              items: relationshipOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() => relationshipStatus = val!);
                _saveProfile();
              },
              decoration: const InputDecoration(labelText: 'Relationship Status'),
            ),

            const SizedBox(height: 16),

            // Bio
            TextField(
              maxLength: 300,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'About You (bio)'),
              onChanged: (val) => bio = val,
              onEditingComplete: _saveProfile,
            ),

            const SizedBox(height: 24),

            // Hobbies
            const Text('Hobbies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.w,
              children: allHobbies.map((hobby) {
                final selected = hobbies.contains(hobby);
                return FilterChip(
                  label: Text(hobby),
                  selected: selected,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) hobbies.add(hobby);
                      else hobbies.remove(hobby);
                    });
                    _saveProfile();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}