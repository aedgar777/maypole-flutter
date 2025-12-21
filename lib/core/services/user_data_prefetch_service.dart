import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service to prefetch and cache user data on login/app start
/// This dramatically reduces visible loading times by warming up the Firestore cache
class UserDataPrefetchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Prefetches all user-related data to warm up the cache
  /// Call this after successful login or when app starts with authenticated user
  Future<void> prefetchUserData(String userId) async {
    debugPrint('🔄 Starting user data prefetch for user: $userId');
    
    try {
      // Run prefetch operations in parallel for better performance
      await Future.wait([
        _prefetchDmThreads(userId),
        _prefetchUserDocument(userId),
      ]);
      
      debugPrint('✅ User data prefetch completed successfully');
    } catch (e) {
      debugPrint('⚠️ Error during user data prefetch: $e');
      // Don't throw - prefetch failures shouldn't block app usage
    }
  }

  /// Prefetches DM threads and recent messages for the user
  Future<void> _prefetchDmThreads(String userId) async {
    try {
      debugPrint('📦 Prefetching DM threads for user: $userId');
      
      // Fetch DM threads - this will cache them
      final threadsSnapshot = await _firestore
          .collection('DMThreads')
          .where('participantIds', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .limit(20) // Prefetch top 20 most recent threads
          .get(const GetOptions(source: Source.server));

      debugPrint('📦 Prefetched ${threadsSnapshot.docs.length} DM threads');

      // Prefetch recent messages for the top 5 most active threads
      final topThreads = threadsSnapshot.docs.take(5);
      
      await Future.wait(
        topThreads.map((threadDoc) => _prefetchDmMessages(threadDoc.id)),
      );
      
      debugPrint('✅ DM threads prefetch completed');
    } catch (e) {
      debugPrint('⚠️ Error prefetching DM threads: $e');
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

      debugPrint('📦 Prefetched ${messagesSnapshot.docs.length} messages for DM thread: $threadId');
    } catch (e) {
      debugPrint('⚠️ Error prefetching messages for thread $threadId: $e');
    }
  }

  /// Prefetches user document which contains maypole thread list
  Future<void> _prefetchUserDocument(String userId) async {
    try {
      debugPrint('📦 Prefetching user document for user: $userId');
      
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists) {
        debugPrint('⚠️ User document does not exist: $userId');
        return;
      }

      debugPrint('✅ User document prefetched successfully');
      
      // Note: Maypole chat messages are intentionally NOT prefetched here
      // as they will use a different caching strategy
      
    } catch (e) {
      debugPrint('⚠️ Error prefetching user document: $e');
    }
  }

  /// Clears all cached data (useful for logout)
  Future<void> clearCache() async {
    try {
      debugPrint('🧹 Clearing Firestore cache...');
      await _firestore.clearPersistence();
      debugPrint('✅ Firestore cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Prefetches data for a specific DM thread
  /// Useful when opening a DM conversation
  Future<void> prefetchDmThread(String threadId) async {
    try {
      debugPrint('📦 Prefetching specific DM thread: $threadId');
      
      // Prefetch thread metadata
      await _firestore
          .collection('DMThreads')
          .doc(threadId)
          .get(const GetOptions(source: Source.server));

      // Prefetch messages
      await _prefetchDmMessages(threadId);
      
      debugPrint('✅ DM thread $threadId prefetched');
    } catch (e) {
      debugPrint('⚠️ Error prefetching DM thread $threadId: $e');
    }
  }
}
