import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads a profile picture to Firebase Storage and returns the download URL.
  /// 
  /// The file is stored at: `ProfilePictures/{userId}/profile.{extension}`
  /// 
  /// [userId] - The Firebase user ID
  /// [filePath] - The local file path to upload
  /// 
  /// Returns the download URL of the uploaded file.
  /// Throws an exception if the upload fails.
  Future<String> uploadProfilePicture(String userId, String filePath) async {
    try {
      debugPrint('Starting profile picture upload for user: $userId');

      // Get file extension
      final extension = filePath
          .split('.')
          .last;

      // Create reference to storage location
      // Path structure: ProfilePictures/{userId}/profile.{extension}
      final storageRef = _storage.ref().child(
          'ProfilePictures/$userId/profile.$extension');

      // Upload file
      UploadTask uploadTask;
      if (kIsWeb) {
        // For web, you'd need to handle this differently
        // This is a placeholder - web file upload requires bytes
        throw UnimplementedError('Web upload not implemented yet');
      } else {
        // For mobile/desktop
        final file = File(filePath);
        uploadTask = storageRef.putFile(file);
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Add timestamp to URL to bust cache when profile picture is updated
      final urlWithTimestamp = '$downloadUrl?t=${DateTime
          .now()
          .millisecondsSinceEpoch}';

      debugPrint(
          'Profile picture uploaded successfully. URL: $urlWithTimestamp');

      return urlWithTimestamp;
    } catch (e) {
      debugPrint('Failed to upload profile picture: $e');
      rethrow;
    }
  }

  /// Updates the user's profile picture URL in Firestore.
  /// 
  /// [userId] - The Firebase user ID
  /// [profilePictureUrl] - The download URL of the profile picture
  Future<void> updateUserProfilePictureUrl(String userId,
      String profilePictureUrl) async {
    try {
      debugPrint('Updating profile picture URL for user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': profilePictureUrl,
      });

      debugPrint('Profile picture URL updated successfully');
    } catch (e) {
      debugPrint('Failed to update profile picture URL: $e');
      rethrow;
    }
  }

  /// Deletes the user's profile picture from Firebase Storage.
  /// 
  /// [userId] - The Firebase user ID
  Future<void> deleteProfilePicture(String userId) async {
    try {
      debugPrint('Deleting profile picture for user: $userId');

      // List all files in the user's profile pictures folder
      final listResult = await _storage
          .ref()
          .child('ProfilePictures/$userId')
          .listAll();

      // Delete all files
      for (final item in listResult.items) {
        await item.delete();
      }

      debugPrint('Profile picture deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete profile picture: $e');
      // Don't rethrow - it's okay if the file doesn't exist
    }
  }
}
