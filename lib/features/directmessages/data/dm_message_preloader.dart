import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/directmessages/domain/direct_message.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';

/// Global service that preloads and caches all DM messages for the current user
/// This ensures instant message display when opening any DM thread
class DmMessagePreloader {
  final DMThreadService _dmThreadService;
  final Ref _ref;
  
  // Store messages for all threads in memory
  final Map<String, List<DirectMessage>> _messageCache = {};
  
  // Store stream subscriptions for cleanup
  final Map<String, StreamSubscription<List<DirectMessage>>> _subscriptions = {};
  
  DmMessagePreloader(this._dmThreadService, this._ref);
  
  /// Start preloading messages for all DM threads
  Future<void> preloadAllDmThreads(String userId) async {
    try {
      debugPrint('🚀 Starting DM preloader for user: $userId');
      
      // Get all DM threads for this user
      final dmThreadsStream = _dmThreadService.getUserDmThreads(userId);
      
      // Listen to thread list changes
      dmThreadsStream.listen((threadMetadataList) {
        debugPrint('📋 Found ${threadMetadataList.length} DM threads to preload');
        
        // Start listening to messages for each thread
        for (final threadMetadata in threadMetadataList) {
          _subscribeToThread(threadMetadata.id);
        }
        
        // Clean up subscriptions for threads that no longer exist
        final activeThreadIds = threadMetadataList.map((t) => t.id).toSet();
        final currentThreadIds = _subscriptions.keys.toSet();
        final threadsToRemove = currentThreadIds.difference(activeThreadIds);
        
        for (final threadId in threadsToRemove) {
          _unsubscribeFromThread(threadId);
        }
      });
    } catch (e) {
      debugPrint('❌ Error starting DM preloader: $e');
    }
  }
  
  /// Subscribe to messages for a specific thread
  void _subscribeToThread(String threadId) {
    // Don't subscribe if already subscribed
    if (_subscriptions.containsKey(threadId)) {
      return;
    }
    
    debugPrint('📥 Subscribing to DM thread: $threadId');
    
    // First, try to load from cache synchronously
    _loadFromCache(threadId);
    
    // Then subscribe to real-time updates
    final subscription = _dmThreadService.getDmMessages(threadId).listen(
      (messages) {
        _messageCache[threadId] = messages;
        debugPrint('💬 Cached ${messages.length} messages for DM thread: $threadId');
      },
      onError: (error) {
        debugPrint('❌ Error loading messages for thread $threadId: $error');
      },
    );
    
    _subscriptions[threadId] = subscription;
  }
  
  /// Load messages from Firestore cache (not network)
  Future<void> _loadFromCache(String threadId) async {
    try {
      final cachedMessages = await _dmThreadService.getCachedDmMessages(threadId);
      if (cachedMessages.isNotEmpty) {
        _messageCache[threadId] = cachedMessages;
        debugPrint('📦 Pre-loaded ${cachedMessages.length} cached messages for thread: $threadId');
      }
    } catch (e) {
      debugPrint('⚠️ Could not load cached messages for thread $threadId: $e');
    }
  }
  
  /// Unsubscribe from a thread
  void _unsubscribeFromThread(String threadId) {
    debugPrint('📤 Unsubscribing from DM thread: $threadId');
    _subscriptions[threadId]?.cancel();
    _subscriptions.remove(threadId);
    _messageCache.remove(threadId);
  }
  
  /// Get cached messages for a thread (returns immediately)
  List<DirectMessage>? getCachedMessages(String threadId) {
    return _messageCache[threadId];
  }
  
  /// Check if messages are cached for a thread
  bool hasCachedMessages(String threadId) {
    return _messageCache.containsKey(threadId) && 
           _messageCache[threadId]!.isNotEmpty;
  }
  
  /// Clean up all subscriptions
  void dispose() {
    debugPrint('🧹 Disposing DM preloader - cleaning up ${_subscriptions.length} subscriptions');
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _messageCache.clear();
  }
}
