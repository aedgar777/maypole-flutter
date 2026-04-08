import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service to prefetch and cache user data on login/app start
/// This dramatically reduces visible loading times by warming up the Firestore cache
class UserDataPrefetchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Prefetches all user-related data to warm up the cache
  /// Call this after successful login or when app starts with authenticated user
  Future<void> prefetchUserData(String userId) async {
    try {
      // Run prefetch operations in parallel for better performance
      await Future.wait([
        _prefetchDmThreads(userId),
        _prefetchUserDocument(userId),
      ]);
      
    } catch (e) {
      // Don't throw - prefetch failures shouldn't block app usage
    }
  }

  /// Prefetches DM threads and recent messages for the user
  Future<void> _prefetchDmThreads(String userId) async {
    try {
      // Fetch DM threads - this will cache them
      final threadsSnapshot = await _firestore
          .collection('DMThreads')
          .where('participantIds', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .limit(20) // Prefetch top 20 most recent threads
          .get(const GetOptions(source: Source.server));


      // Prefetch recent messages for the top 5 most active threads
      final topThreads = threadsSnapshot.docs.take(5);
      
      await Future.wait(
        topThreads.map((threadDoc) => _prefetchDmMessages(threadDoc.id)),
      );
      
    } catch (e) {
    }
  }

  /// Prefetches messages for a specific DM thread
  Future<void> _prefetchDmMessages(String threadId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('DMThreads')
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50) // Prefetch last 50 messages
          .get(const GetOptions(source: Source.server));

    } catch (e) {
    }
  }

  /// Prefetches user document which contains maypole thread list
  Future<void> _prefetchUserDocument(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists) {
        return;
      }

      // Note: Maypole chat messages are intentionally NOT prefetched here
      // as they will use a different caching strategy
      
    } catch (e) {
    }
  }

  /// Clears all cached data (useful for logout)
  Future<void> clearCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
    }
  }

  /// Prefetches data for a specific DM thread
  /// Useful when opening a DM conversation
  Future<void> prefetchDmThread(String threadId) async {
    try {
      
      // Prefetch thread metadata
      await _firestore
          .collection('DMThreads')
          .doc(threadId)
          .get(const GetOptions(source: Source.server));

      // Prefetch messages
      await _prefetchDmMessages(threadId);
      
    } catch (e) {
    }
  }
}
