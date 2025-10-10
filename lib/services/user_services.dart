import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch current user's profile data (including pic URL)
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Upload profile picture
  Future<String?> uploadProfilePic(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null || imageFile == null) return null;

    try {
      // Create UID-specific path
      final fileName = 'profile.jpg';
      final ref = _storage.ref().child('profile_pics/${user.uid}/$fileName');

      // Upload file
      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with URL
      await _firestore.collection('users').doc(user.uid).update({
        'profilePicUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // Clear cache on logout (optional, helps with persistent issues)
  Future<void> clearLocalData() async {
    // You can add logic to clear SharedPreferences or local storage if used
    // For images, CachedNetworkImage handles eviction automatically, but you can use image_cache_manager if needed
  }
}