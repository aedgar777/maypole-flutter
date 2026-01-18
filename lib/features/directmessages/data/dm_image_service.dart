import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

/// Service for uploading images to Firebase Storage for DM messages
class DmImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static const int maxImagesPerMessage = 5;

  /// Uploads an image to Firebase Storage for a DM thread
  /// 
  /// [threadId] - The ID of the DM thread
  /// [userId] - The uploader's Firebase user ID
  /// [filePath] - The local file path of the image to upload
  /// 
  /// Returns the download URL of the uploaded image
  /// Throws an exception if upload fails
  Future<String> uploadImage({
    required String threadId,
    required String userId,
    required String filePath,
  }) async {
    try {
      debugPrint('Starting DM image upload for thread: $threadId');

      // Get file extension
      final extension = filePath.split('.').last.toLowerCase();
      
      // Validate extension
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        throw Exception('Invalid file type. Only images are allowed.');
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${userId}_$timestamp.$extension';

      // Create reference to storage location
      // Path: dm_images/{threadId}/{filename}
      final storageRef = _storage.ref().child('dm_images/$threadId/$filename');

      // Upload file
      UploadTask uploadTask;
      if (kIsWeb) {
        throw UnimplementedError('Web upload not implemented yet');
      } else {
        final file = File(filePath);
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(
            contentType: 'image/$extension',
            customMetadata: {
              'uploadedBy': userId,
              'threadId': threadId,
            },
          ),
        );
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('DM image uploaded successfully. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Failed to upload DM image: $e');
      rethrow;
    }
  }

  /// Uploads multiple images for a DM message
  /// 
  /// [threadId] - The ID of the DM thread
  /// [userId] - The uploader's Firebase user ID
  /// [filePaths] - List of local file paths to upload (max 5)
  /// 
  /// Returns a list of download URLs for the uploaded images
  /// Throws an exception if upload fails or if more than 5 images are provided
  Future<List<String>> uploadMultipleImages({
    required String threadId,
    required String userId,
    required List<String> filePaths,
  }) async {
    if (filePaths.length > maxImagesPerMessage) {
      throw Exception('Cannot upload more than $maxImagesPerMessage images per message');
    }

    final List<String> uploadedUrls = [];
    
    for (final filePath in filePaths) {
      try {
        final url = await uploadImage(
          threadId: threadId,
          userId: userId,
          filePath: filePath,
        );
        uploadedUrls.add(url);
      } catch (e) {
        // Clean up already uploaded images if one fails
        for (final uploadedUrl in uploadedUrls) {
          try {
            final ref = _storage.refFromURL(uploadedUrl);
            await ref.delete();
            debugPrint('Cleaned up uploaded image after failure: $uploadedUrl');
          } catch (deleteError) {
            debugPrint('Failed to clean up image: $deleteError');
          }
        }
        rethrow;
      }
    }

    return uploadedUrls;
  }

  /// Deletes images from Firebase Storage
  /// 
  /// [imageUrls] - List of image URLs to delete
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
        debugPrint('Deleted DM image from storage: $imageUrl');
      } catch (e) {
        debugPrint('Failed to delete DM image from storage: $e');
        // Don't throw - continue deleting other images
      }
    }
  }
}
