import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import '../../data/maypole_chat_service.dart';
import '../maypole_chat_providers.dart';

class MaypoleChatViewModel extends AsyncNotifier<List<MaypoleMessage>> {
  MaypoleChatViewModel(this._threadId);

  final String _threadId;
  late final MaypoleChatService _threadService;
  StreamSubscription<List<MaypoleMessage>>? _messagesSubscription;
  bool _isLoadingMore = false;

  @override
  Future<List<MaypoleMessage>> build() async {
    _threadService = ref.read(maypoleChatThreadServiceProvider);

    // Cancel subscription when the provider is disposed
    ref.onDispose(() {
      _messagesSubscription?.cancel();
    });

    // Use smart cache-first strategy for maypole messages
    await _initWithSmartCache();

    // Return empty list initially, cache or stream will update it
    return [];
  }

  /// Smart cache initialization that handles both scenarios:
  /// 1. Cache is still current (show immediately)
  /// 2. Cache is stale due to many new messages (fetch fresh, show transition)
  Future<void> _initWithSmartCache() async {
    try {
      // Step 1: Try to load from cache for instant display
      final cachedMessages = await _threadService.getCachedMessages(_threadId);
      
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        // Show cached messages immediately
        state = AsyncValue.data(cachedMessages);
        debugPrint('📦 Displaying ${cachedMessages.length} cached messages');
        
        // Step 2: Validate cache in background (only 1 document read!)
        final validationResult = await _threadService.validateCachedMessages(
          _threadId,
          cachedMessages,
        );
        
        switch (validationResult) {
          case CacheValidationResult.cacheValid:
            // Cache is current, just set up stream for future updates
            debugPrint('✅ Cache validated - setting up stream for real-time updates');
            _initStream();
            break;
            
          case CacheValidationResult.cacheStale:
            // Cache is stale - need to fetch fresh messages
            debugPrint('🔄 Cache stale - fetching fresh messages');
            
            // Fetch fresh messages from server
            final freshMessages = await _threadService.getFreshMessages(_threadId);
            
            // Check if any cached messages are still in the fresh set
            final cachedIds = cachedMessages.map((m) => m.id).toSet();
            final freshIds = freshMessages.map((m) => m.id).toSet();
            final hasOverlap = cachedIds.intersection(freshIds).isNotEmpty;
            
            if (hasOverlap) {
              // Some cached messages still in top 100 - smooth transition
              debugPrint('✅ Smooth transition: some cached messages still relevant');
              state = AsyncValue.data(freshMessages);
            } else {
              // No overlap - hundreds of new messages pushed old ones out
              debugPrint('⚠️ Cache completely outdated - hundreds of new messages');
              state = AsyncValue.data(freshMessages);
            }
            
            // Now set up stream for real-time updates
            _initStream();
            break;
            
          case CacheValidationResult.noCache:
            // Shouldn't happen since we checked above, but handle gracefully
            _initStream();
            break;
        }
      } else {
        // No cache available, use standard initialization
        debugPrint('📭 No cache available - loading from server');
        _init();
      }
    } catch (e) {
      debugPrint('⚠️ Error in smart cache init: $e');
      // Fallback to standard initialization
      _init();
    }
  }

  /// Standard initialization - sets up stream directly
  void _init() {
    state = const AsyncValue.loading();
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _threadService.getMessages(_threadId).listen((messages) {
      state = AsyncValue.data(messages);
    }, onError: (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  /// Stream-only initialization (when cache is validated)
  /// Doesn't show loading state since we already have cached data displayed
  void _initStream() {
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _threadService.getMessages(_threadId).listen((messages) {
      state = AsyncValue.data(messages);
    }, onError: (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  Future<void> sendMessage(String maypoleName,
      String body,
      DomainUser sender, {
        List<String> taggedUserIds = const [],
      }) async {
    try {
      await _threadService.sendMessage(
        _threadId,
        maypoleName,
        body,
        sender,
        taggedUserIds: taggedUserIds,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendPlaceMessage(String maypoleName,
      String body,
      DomainUser sender, {
        List<String> taggedUserIds = const [],
      }) async {
    try {
      await _threadService.sendMaypoleMessage(
        _threadId,
        maypoleName,
        body,
        sender,
        taggedUserIds: taggedUserIds,
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
          await _threadService.getMoreMessages(_threadId, lastMessage);
      state = AsyncValue.data([...currentMessages, ...newMessages]);
    } catch (e) {
      // Maybe show a snackbar or some other error indication
      debugPrint('Error loading more messages: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> deleteMessage(MaypoleMessage message) async {
    try {
      await _threadService.deleteMessage(_threadId, message);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider to hold the threadId parameter
final maypoleChatThreadIdProvider = Provider<String>((
    ref) => throw UnimplementedError());
