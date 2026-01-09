import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../domain/maypole_image.dart';
import '../domain/maypole_message.dart';

/// Service for managing maypole images (upload, fetch, delete)
class MaypoleImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Rate limiting: max 10 images per user per maypole per hour
  static const int _maxImagesPerHour = 10;
  static const int _imageLimit = 50; // Number of images to fetch at once

  /// Uploads an image to a maypole chat room
  /// 
  /// [maypoleId] - The ID of the maypole
  /// [maypoleName] - The name of the maypole
  /// [userId] - The uploader's Firebase user ID
  /// [username] - The uploader's username
  /// [filePath] - The local file path of the image to upload
  /// 
  /// Returns the MaypoleImage object for the uploaded image
  /// Throws an exception if rate limit is exceeded or upload fails
  Future<MaypoleImage> uploadImage({
    required String maypoleId,
    required String maypoleName,
    required String userId,
    required String username,
    required String filePath,
  }) async {
    // Check rate limit
    await _checkRateLimit(maypoleId, userId);

    try {
      debugPrint('Starting maypole image upload for maypole: $maypoleId');

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
      // Path: maypole_images/{maypoleId}/{filename}
      final storageRef = _storage.ref().child('maypole_images/$maypoleId/$filename');

      // Upload file
      UploadTask uploadTask;
      if (kIsWeb) {
        throw UnimplementedError('Web upload not implemented yet');
      } else {
        final file = File(filePath);
        // Compress/resize if needed (optional - could be handled by Cloud Function)
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(
            contentType: 'image/$extension',
            customMetadata: {
              'uploadedBy': userId,
              'maypoleId': maypoleId,
              'maypoleName': maypoleName,
            },
          ),
        );
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image uploaded successfully. URL: $downloadUrl');

      // Create MaypoleImage object
      final imageId = _firestore
          .collection('maypoles')
          .doc(maypoleId)
          .collection('images')
          .doc()
          .id;

      final maypoleImage = MaypoleImage(
        id: imageId,
        maypoleId: maypoleId,
        uploaderId: userId,
        uploaderName: username,
        uploadedAt: DateTime.now(),
        storageUrl: downloadUrl,
      );

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Save image metadata
      final imageRef = _firestore
          .collection('maypoles')
          .doc(maypoleId)
          .collection('images')
          .doc(imageId);
      batch.set(imageRef, maypoleImage.toMap());

      // Increment image count on maypole document
      final maypoleRef = _firestore.collection('maypoles').doc(maypoleId);
      batch.set(maypoleRef, {
        'id': maypoleId,
        'name': maypoleName,
        'imageCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Create a chat notification message
      final notificationMessage = MaypoleMessage(
        senderName: username,
        senderId: userId,
        senderProfilePictureUrl: '', // Not needed for notification messages
        timestamp: DateTime.now(),
        body: 'has added an image',
        messageType: 'image_upload',
        imageId: imageId,
      );

      final messageRef = maypoleRef.collection('messages').doc();
      batch.set(messageRef, notificationMessage.toMap());

      // Commit all changes atomically
      await batch.commit();

      debugPrint('Image metadata and notification saved to Firestore');

      return maypoleImage;
    } catch (e) {
      debugPrint('Failed to upload maypole image: $e');
      rethrow;
    }
  }

  /// Checks if the user has exceeded the rate limit for uploading images
  Future<void> _checkRateLimit(String maypoleId, String userId) async {
    // TODO: Rate limiting temporarily disabled - index mismatch issue
    // The composite index for sorting doesn't work for the rate limit query
    // We'll need to either: create a separate index, or count client-side
    debugPrint('⚠️ Rate limiting temporarily disabled - index configuration issue');
    return;
    
    /* Original code - needs specific index
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    final recentImages = await _firestore
        .collection('maypoles')
        .doc(maypoleId)
        .collection('images')
        .where('uploaderId', isEqualTo: userId)
        .where('uploadedAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
        .get();

    if (recentImages.docs.length >= _maxImagesPerHour) {
      throw Exception(
        'Rate limit exceeded. You can upload up to $_maxImagesPerHour images per hour.',
      );
    }
    */
  }

  /// Fetches images for a maypole in chronological order (most recent first)
  /// 
  /// [maypoleId] - The ID of the maypole
  /// [limit] - Number of images to fetch (default: 50)
  /// 
  /// Returns a stream of MaypoleImage objects
  Stream<List<MaypoleImage>> getImages(String maypoleId, {int? limit}) {
    debugPrint('📸 Setting up images stream for maypole: $maypoleId');
    
    return _firestore
        .collection('maypoles')
        .doc(maypoleId)
        .collection('images')
        .orderBy('uploadedAt', descending: true)
        .limit(limit ?? _imageLimit)
        .snapshots()
        .map((snapshot) {
      debugPrint('📸 Stream snapshot received: ${snapshot.docs.length} images');
      return snapshot.docs
          .map((doc) => MaypoleImage.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }

  /// Fetches more images for pagination
  /// 
  /// [maypoleId] - The ID of the maypole
  /// [lastImage] - The last image from the previous fetch
  /// [limit] - Number of images to fetch (default: 50)
  Future<List<MaypoleImage>> getMoreImages(
    String maypoleId,
    MaypoleImage lastImage, {
    int? limit,
  }) async {
    final snapshot = await _firestore
        .collection('maypoles')
        .doc(maypoleId)
        .collection('images')
        .orderBy('uploadedAt', descending: true)
        .startAfter([Timestamp.fromDate(lastImage.uploadedAt)])
        .limit(limit ?? _imageLimit)
        .get();

    return snapshot.docs
        .map((doc) => MaypoleImage.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  /// Deletes an image from the maypole
  /// Only the uploader can delete their own images
  /// 
  /// [maypoleId] - The ID of the maypole
  /// [imageId] - The ID of the image to delete
  /// [userId] - The current user's ID (must match uploaderId)
  Future<void> deleteImage(String maypoleId, String imageId, String userId) async {
    try {
      // Get the image document
      final imageDoc = await _firestore
          .collection('maypoles')
          .doc(maypoleId)
          .collection('images')
          .doc(imageId)
          .get();

      if (!imageDoc.exists) {
        throw Exception('Image not found');
      }

      final imageData = imageDoc.data()!;
      final uploaderId = imageData['uploaderId'] as String?;

      // Verify the user is the uploader
      if (uploaderId != userId) {
        throw Exception('You can only delete your own images');
      }

      // Get the storage URL to delete from storage
      final storageUrl = imageData['storageUrl'] as String?;

      // Delete from Firestore
      await imageDoc.reference.delete();

      // Decrement image count
      await _firestore.collection('maypoles').doc(maypoleId).update({
        'imageCount': FieldValue.increment(-1),
      });

      // Delete from Storage (if URL exists)
      if (storageUrl != null && storageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(storageUrl);
          await ref.delete();
          debugPrint('Deleted image from storage: $storageUrl');
        } catch (e) {
          debugPrint('Failed to delete image from storage (may not exist): $e');
          // Don't throw - Firestore deletion succeeded, which is most important
        }
      }

      debugPrint('Image deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      rethrow;
    }
  }

  /// Gets cached images if available
  Future<List<MaypoleImage>?> getCachedImages(String maypoleId) async {
    try {
      final cacheSnapshot = await _firestore
          .collection('maypoles')
          .doc(maypoleId)
          .collection('images')
          .orderBy('uploadedAt', descending: true)
          .limit(_imageLimit)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isEmpty) {
        debugPrint('📦 No cached images found for maypole: $maypoleId');
        return null;
      }

      debugPrint('📦 Retrieved ${cacheSnapshot.docs.length} cached images for maypole: $maypoleId');
      return cacheSnapshot.docs
          .map((doc) => MaypoleImage.fromMap(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Cache miss for maypole images $maypoleId: $e');
      return null;
    }
  }
}
