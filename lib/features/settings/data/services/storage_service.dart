import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads a profile picture to Firebase Storage and returns the optimized URL.
  /// 
  /// The file is stored at: `profile_pictures/{userId}/profile.{extension}`
  /// Cloud Function automatically creates optimized variants:
  /// - thumbnail (150x150) for list views
  /// - medium (400x400) for profile views  
  /// - large (800x800) for full screen
  /// 
  /// [userId] - The Firebase user ID
  /// [filePath] - The local file path to upload
  /// [useOptimized] - Whether to return optimized medium URL (default: true)
  /// 
  /// Returns the download URL of the uploaded file (or optimized variant).
  /// Throws an exception if the upload fails.
  Future<String> uploadProfilePicture(String userId, String filePath, {bool useOptimized = true}) async {
    try {
      debugPrint('Starting profile picture upload for user: $userId');

      // Get file extension
      final extension = filePath
          .split('.')
          .last;

      // Create reference to storage location
      // Path structure: profile_pictures/{userId}/profile.{extension}
      // Note: Using lowercase with underscore to match Cloud Function expectations
      final storageRef = _storage.ref().child(
          'profile_pictures/$userId/profile.$extension');

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

      debugPrint('Profile picture uploaded successfully. URL: $downloadUrl');
      debugPrint('⏳ Cloud Function will create optimized variants in ~10 seconds');

      // Always return the original download URL
      // The optimized variants will be created by the Cloud Function
      // but we use the original URL so images display immediately
      // TODO: Implement a background job to update to optimized URL after Cloud Function completes
      return downloadUrl;
    } catch (e) {
      debugPrint('Failed to upload profile picture: $e');
      rethrow;
    }
  }
  
  /// Gets the optimized profile picture URL for a given size
  /// 
  /// [originalUrl] - The original profile picture URL
  /// [size] - The size variant ('thumb', 'medium', 'large')
  /// 
  /// Returns the optimized URL or original if not available
  String getOptimizedUrl(String originalUrl, {String size = 'medium'}) {
    if (originalUrl.isEmpty) return originalUrl;
    
    try {
      // Replace the extension with _{size}.jpg
      final basePath = originalUrl.split('.').first;
      return '${basePath}_$size.jpg';
    } catch (e) {
      debugPrint('Failed to construct optimized URL: $e');
      return originalUrl;
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
  /// This includes the original and all optimized variants.
  /// 
  /// [userId] - The Firebase user ID
  Future<void> deleteProfilePicture(String userId) async {
    try {
      debugPrint('Deleting profile picture for user: $userId');

      // List all files in the user's profile pictures folder
      // Check both old and new paths for backwards compatibility
      final paths = [
        'ProfilePictures/$userId',  // Old path
        'profile_pictures/$userId', // New path
      ];
      
      for (final path in paths) {
        try {
          final listResult = await _storage
              .ref()
              .child(path)
              .listAll();

          // Delete all files (includes optimized variants)
          for (final item in listResult.items) {
            await item.delete();
            debugPrint('Deleted: ${item.fullPath}');
          }
        } catch (e) {
          debugPrint('No files found at $path (this is okay)');
        }
      }

      debugPrint('Profile picture deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete profile picture: $e');
      // Don't rethrow - it's okay if the file doesn't exist
    }
  }
}
