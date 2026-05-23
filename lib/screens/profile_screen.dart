import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _isUploading = false;

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
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => currentPosition = position);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (photoUrls.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 10 photos allowed')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [AndroidUiSettings(toolbarTitle: 'Edit Photo', toolbarColor: Colors.deepPurple, toolbarWidgetColor: Colors.white)],
      );

      if (cropped == null) return;

      final ref = _storage.ref().child('profile_photos/${user!.uid}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(cropped.path));
      final url = await ref.getDownloadURL();

      setState(() => photoUrls.add(url));
      await _saveProfile();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
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
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: Colors.deepPurple.shade900),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0033), Color(0xFF2C0A4D), Colors.black87],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Large profile picture
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[800],
                backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
                child: profilePicUrl == null
                    ? const Icon(Icons.person, size: 110, color: Colors.white70)
                    : null,
              ),
              const SizedBox(height: 32),

              // Photo grid
              if (_isUploading)
                const CircularProgressIndicator(color: Colors.pinkAccent)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: photoUrls.length + 1,
                  itemBuilder: (context, index) {
                    if (index == photoUrls.length) {
                      return GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.pinkAccent, width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(url, fit: BoxFit.cover),
                          ),
                        ),
                        if (profilePicUrl == url)
                          const Positioned(top: 8, right: 8, child: Icon(Icons.star, color: Colors.amber, size: 32)),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 40),

              // Relationship Status
              Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DropdownButtonFormField<String>(
                    value: relationshipStatus,
                    items: relationshipOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => relationshipStatus = val);
                        _saveProfile();
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Relationship Status', border: InputBorder.none),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bio
              Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    maxLength: 300,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'About You', border: InputBorder.none),
                    onChanged: (val) => bio = val,
                    onEditingComplete: _saveProfile,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Hobbies
              const Text('Hobbies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: allHobbies.map((hobby) {
                  final selected = hobbies.contains(hobby);
                  return FilterChip(
                    label: Text(hobby),
                    selected: selected,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    selectedColor: Colors.pinkAccent,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
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

              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}