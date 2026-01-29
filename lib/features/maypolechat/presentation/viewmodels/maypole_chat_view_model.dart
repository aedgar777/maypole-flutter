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

    // Keep this provider alive even when not actively watched
    // This prevents rebuilding and allows instant cache access when returning
    ref.keepAlive();

    // Cancel subscription when the provider is disposed
    ref.onDispose(() {
      _messagesSubscription?.cancel();
    });

    // Try to load from cache synchronously first
    final cachedMessages = await _threadService.getCachedMessages(_threadId);
    
    if (cachedMessages != null && cachedMessages.isNotEmpty) {
      debugPrint('📦 Returning ${cachedMessages.length} cached messages immediately');
      
      // Set up stream and validation in background (don't await)
      _validateAndSetupStream(cachedMessages);
      
      // Return cached data immediately - no loading state!
      return cachedMessages;
    } else {
      // No cache - set up stream and return empty (will load from server)
      debugPrint('📭 No cache - initializing from server');
      _init();
      return [];
    }
  }

  /// Validates cache and sets up stream in background
  Future<void> _validateAndSetupStream(List<MaypoleMessage> cachedMessages) async {
    try {
      // Validate cache in background (only 1 document read!)
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
          
          // Update state with fresh messages
          state = AsyncValue.data(freshMessages);
          
          // Now set up stream for real-time updates
          _initStream();
          break;
          
        case CacheValidationResult.noCache:
          _initStream();
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Error validating cache: $e');
      _initStream();
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
        String address = '',
        double? latitude,
        double? longitude,
        double? senderLatitude,
        double? senderLongitude,
        String? placeType,
      }) async {
    try {
      await _threadService.sendMessage(
        _threadId,
        maypoleName,
        body,
        sender,
        taggedUserIds: taggedUserIds,
        address: address,
        latitude: latitude,
        longitude: longitude,
        senderLatitude: senderLatitude,
        senderLongitude: senderLongitude,
        placeType: placeType,
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
