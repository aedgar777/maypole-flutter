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

    // Cancel subscription when the provider is disposed
    ref.onDispose(() {
      _messagesSubscription?.cancel();
    });

    // Try to load from cache first for instant display
    await _initWithCache();

    // Return empty list initially, cache or stream will update it
    return [];
  }

  /// Initialize with cache-first strategy
  /// Shows cached data immediately, then sets up stream for real-time updates
  Future<void> _initWithCache() async {
    try {
      // First, try to load from cache for instant display
      final cachedMessages = await _threadService.getCachedDmMessages(_threadId);
      
      if (cachedMessages.isNotEmpty) {
        // Show cached data immediately
        state = AsyncValue.data(cachedMessages);
        developer.log('Loaded ${cachedMessages.length} cached messages', name: 'DmViewModel');
      }
    } catch (e) {
      developer.log('Error loading cached messages: $e', name: 'DmViewModel');
      // Continue to stream setup even if cache fails
    }
    
    // Now set up the stream for real-time updates
    _initStream();
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

  Future<void> sendDmMessage(String body,
      String senderId,
      String senderUsername,
      String recipientId,) async {
    try {
      await _threadService.sendDmMessage(
        _threadId,
        body,
        senderId,
        senderUsername,
        recipientId,
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
