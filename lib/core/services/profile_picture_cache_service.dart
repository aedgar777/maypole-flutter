import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that caches user profile pictures to avoid redundant Firestore reads
/// Uses Riverpod's built-in caching with family providers
class ProfilePictureCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // In-memory cache for batch-fetched profile pictures
  final Map<String, String> _batchCache = {};
  
  /// Fetches a user's profile picture URL from Firestore
  /// Returns empty string if user not found or has no profile picture
  Future<String> getProfilePictureUrl(String userId) async {
    if (userId.isEmpty) {
      debugPrint('⚠️ getProfilePictureUrl called with empty userId');
      return '';
    }
    
    debugPrint('🔍 getProfilePictureUrl called for user: $userId');
    
    // Check batch cache first
    if (_batchCache.containsKey(userId)) {
      final cachedUrl = _batchCache[userId]!;
      debugPrint('🎯 Using batch-cached profile picture for $userId: ${cachedUrl.isEmpty ? "EMPTY" : cachedUrl.substring(0, 50)}...');
      return cachedUrl;
    }
    
    // Skip Firestore cache, always fetch from server for now to debug
    // try {
    //   final userDoc = await _firestore
    //       .collection('users')
    //       .doc(userId)
    //       .get(const GetOptions(source: Source.cache));
    //   
    //   if (userDoc.exists) {
    //     final data = userDoc.data();
    //     debugPrint('📦 User document data from cache: ${data?.keys.toList()}');
    //     final profilePictureUrl = data?['profilePictureUrl'] as String? ?? '';
    //     debugPrint('📦 profilePictureUrl field value: "${profilePictureUrl}"');
    //     debugPrint('📦 Loaded from Firestore cache for $userId: ${profilePictureUrl.isEmpty ? "EMPTY" : profilePictureUrl.substring(0, 50)}...');
    //     if (profilePictureUrl.isNotEmpty) {
    //       _batchCache[userId] = profilePictureUrl;
    //       return profilePictureUrl;
    //     }
    //   } else {
    //     debugPrint('⚠️ User document does not exist in cache for $userId');
    //   }
    // } catch (e) {
    //   debugPrint('⚠️ Cache miss for user $userId, fetching from server: $e');
    // }
    
    // Cache miss or empty profile picture, fetch from server
    try {
      debugPrint('🌐 Fetching from Firestore server for user: $userId');
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));
      
      if (userDoc.exists) {
        final data = userDoc.data();
        debugPrint('🌐 User document data from SERVER:');
        debugPrint('🌐   Keys: ${data?.keys.toList()}');
        debugPrint('🌐   Username: ${data?['username']}');
        debugPrint('🌐   Email: ${data?['email']}');
        debugPrint('🌐   ProfilePictureUrl exists: ${data?.containsKey('profilePictureUrl')}');
        final profilePictureUrl = data?['profilePictureUrl'] as String? ?? '';
        debugPrint('🌐   ProfilePictureUrl value: "${profilePictureUrl}"');
        debugPrint('🌐   ProfilePictureUrl length: ${profilePictureUrl.length}');
        _batchCache[userId] = profilePictureUrl;
        return profilePictureUrl;
      } else {
        debugPrint('❌ User document does NOT EXIST in Firestore for $userId');
      }
    } catch (e) {
      debugPrint('❌ Error fetching profile picture for user $userId: $e');
    }
    
    debugPrint('❌ Returning empty string for user $userId');
    return '';
  }
  
  /// Batch fetches profile pictures for multiple users in a single Firestore query
  /// This is much more efficient than fetching users one-by-one
  /// Returns a map of userId -> profilePictureUrl
  Future<Map<String, String>> batchGetProfilePictureUrls(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    
    // Filter out empty IDs and remove duplicates
    final uniqueUserIds = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueUserIds.isEmpty) return {};
    
    // Check batch cache first
    final results = <String, String>{};
    final uncachedUserIds = <String>[];
    
    for (final userId in uniqueUserIds) {
      if (_batchCache.containsKey(userId)) {
        results[userId] = _batchCache[userId]!;
      } else {
        uncachedUserIds.add(userId);
      }
    }
    
    if (uncachedUserIds.isEmpty) {
      debugPrint('🎯 All ${uniqueUserIds.length} profile pictures from batch cache');
      return results;
    }
    
    debugPrint('📦 Batch fetching ${uncachedUserIds.length} profile pictures');
    
    try {
      // Firestore 'in' query supports up to 30 items at once
      // If we have more, we need to batch them
      final batchSize = 30;
      for (var i = 0; i < uncachedUserIds.length; i += batchSize) {
        final batchUserIds = uncachedUserIds.skip(i).take(batchSize).toList();
        
        // Try cache first
        try {
          final cacheSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batchUserIds)
              .get(const GetOptions(source: Source.cache));
          
          if (cacheSnapshot.docs.isNotEmpty) {
            for (final doc in cacheSnapshot.docs) {
              final data = doc.data();
              final profilePictureUrl = data['profilePictureUrl'] as String? ?? '';
              results[doc.id] = profilePictureUrl;
              _batchCache[doc.id] = profilePictureUrl;
            }
            debugPrint('📦 Loaded ${cacheSnapshot.docs.length} from Firestore cache');
          }
        } catch (e) {
          debugPrint('⚠️ Cache miss for batch, fetching from server');
        }
        
        // Fetch any remaining from server
        final missingIds = batchUserIds.where((id) => !results.containsKey(id)).toList();
        if (missingIds.isNotEmpty) {
          final serverSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: missingIds)
              .get(const GetOptions(source: Source.server));
          
          for (final doc in serverSnapshot.docs) {
            final data = doc.data();
            final profilePictureUrl = data['profilePictureUrl'] as String? ?? '';
            results[doc.id] = profilePictureUrl;
            _batchCache[doc.id] = profilePictureUrl;
          }
          debugPrint('🌐 Loaded ${serverSnapshot.docs.length} from server in batch');
        }
      }
      
      // Add empty strings for users not found
      for (final userId in uncachedUserIds) {
        if (!results.containsKey(userId)) {
          results[userId] = '';
          _batchCache[userId] = '';
        }
      }
      
      debugPrint('✅ Batch fetch complete: ${results.length} users');
      return results;
    } catch (e) {
      debugPrint('❌ Error in batch fetch: $e');
      // Return whatever we got
      return results;
    }
  }
  
  /// Prefetches profile pictures for a list of users in the background
  /// This warms up the cache without blocking the UI
  void prefetchProfilePictures(List<String> userIds) {
    if (userIds.isEmpty) return;
    
    // Run in background, don't await
    batchGetProfilePictureUrls(userIds).then((_) {
      debugPrint('✓ Prefetch complete for ${userIds.length} users');
    }).catchError((e) {
      debugPrint('⚠️ Prefetch failed: $e');
    });
  }
  
  /// Clears the in-memory batch cache
  /// Useful when user logs out or switches accounts
  void clearCache() {
    _batchCache.clear();
    debugPrint('🗑️ Profile picture cache cleared');
  }
}

/// Provider for the profile picture cache service
/// Using keepAlive to maintain cache across widget rebuilds
final profilePictureCacheServiceProvider = Provider<ProfilePictureCacheService>((ref) {
  final service = ProfilePictureCacheService();
  
  // Clear cache when provider is disposed (e.g., user logs out)
  ref.onDispose(() {
    service.clearCache();
  });
  
  return service;
});

/// Family provider that caches profile picture URLs per user ID
/// This automatically handles caching and deduplication
/// Using autoDispose to allow refreshing when needed
final profilePictureUrlProvider = FutureProvider.family.autoDispose<String, String>((ref, userId) async {
  if (userId.isEmpty) return '';
  
  final service = ref.watch(profilePictureCacheServiceProvider);
  return await service.getProfilePictureUrl(userId);
});

/// Batch provider that fetches multiple profile pictures at once
/// Much more efficient than individual fetches
final batchProfilePictureUrlsProvider = FutureProvider.family<Map<String, String>, List<String>>((ref, userIds) async {
  if (userIds.isEmpty) return {};
  
  final service = ref.watch(profilePictureCacheServiceProvider);
  return await service.batchGetProfilePictureUrls(userIds);
});
