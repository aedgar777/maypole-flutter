import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/directmessages/domain/direct_message.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';

class DmViewModel extends AsyncNotifier<List<DirectMessage>> {
  DmViewModel(this._threadId);

  final String _threadId;
  late final DMThreadService _threadService;
  StreamSubscription<List<DirectMessage>>? _messagesSubscription;
  bool _isLoadingMore = false;

  @override
  Future<List<DirectMessage>> build() async {
    _threadService = ref.read(dmThreadServiceProvider);

    // Keep this provider alive even when not actively watched
    // This prevents rebuilding and allows instant cache access when returning
    ref.keepAlive();

    // Cancel subscription when the provider is disposed
    ref.onDispose(() {
      _messagesSubscription?.cancel();
    });

    // First, try to get messages from the global preloader
    final preloader = ref.read(dmMessagePreloaderProvider);
    final preloadedMessages = preloader.getCachedMessages(_threadId);
    
    if (preloadedMessages != null && preloadedMessages.isNotEmpty) {
      developer.log('⚡ Returning ${preloadedMessages.length} preloaded DM messages INSTANTLY', name: 'DmViewModel');
      
      // Still set up stream for this specific view model to handle updates
      _initStream();
      
      // Return preloaded data immediately - zero delay!
      return preloadedMessages;
    }
    
    // Fallback: Try to load from Firestore cache
    final cachedMessages = await _threadService.getCachedDmMessages(_threadId);
    
    if (cachedMessages.isNotEmpty) {
      developer.log('📦 Returning ${cachedMessages.length} cached DM messages from Firestore', name: 'DmViewModel');
      
      // Set up stream in background (don't await)
      _initStream();
      
      // Return cached data immediately - no loading state!
      return cachedMessages;
    } else {
      // No cache - set up stream and return empty (will load from server)
      developer.log('📭 No cache - initializing DMs from server', name: 'DmViewModel');
      _initStream();
      return [];
    }
  }

  void _initStream() {
    // Don't show loading if we already have cached data
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _threadService.getDmMessages(_threadId).listen((messages) {
      state = AsyncValue.data(messages);
    }, onError: (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  Future<void> sendDmMessage(
    String body,
    String senderId,
    String senderUsername,
    String recipientId, {
    List<String> imageUrls = const [],
  }) async {
    try {
      await _threadService.sendDmMessage(
        _threadId,
        body,
        senderId,
        senderUsername,
        recipientId,
        imageUrls: imageUrls,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !state.hasValue || state.value!.isEmpty) return;

    _isLoadingMore = true;
    try {
      final currentMessages = state.value!;
      final lastMessage = currentMessages.last;
      final newMessages =
          await _threadService.getMoreDmMessages(_threadId, lastMessage);
      state = AsyncValue.data([...currentMessages, ...newMessages]);
    } catch (e) {
      // Log error without using print in production
      developer.log('Error loading more messages: $e', name: 'DmViewModel');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> deleteDmMessage(DirectMessage message, String userId, String username) async {
    try {
      if (message.id == null) {
        throw Exception('Message ID is required for deletion');
      }
      await _threadService.deleteDmMessage(_threadId, message.id!, userId, username);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider to hold the threadId parameter
final dmThreadIdProvider = Provider<String>((
    ref) => throw UnimplementedError());
