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

    _init();

    // Return empty list initially, the stream will update it
    return [];
  }

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
}

// Provider to hold the threadId parameter
final maypoleChatThreadIdProvider = Provider<String>((
    ref) => throw UnimplementedError());
