import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import '../../data/maypole_chat_service.dart';

class MaypoleChatViewModel extends StateNotifier<AsyncValue<List<MaypoleMessage>>> {
  final MaypoleChatService _threadService;
  final String _threadId;
  StreamSubscription<List<MaypoleMessage>>? _messagesSubscription;
  bool _isLoadingMore = false;

  MaypoleChatViewModel(this._threadService, this._threadId)
      : super(const AsyncValue.loading()) {
    _init();
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

  Future<void> sendMessage(String maypoleName, String body, DomainUser sender) async {
    try {
      await _threadService.sendMessage(_threadId, maypoleName, body, sender);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendPlaceMessage(
      String maypoleName, String body, DomainUser sender) async {
    try {
      await _threadService.sendPlaceMessage(_threadId, maypoleName, body, sender);
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
      print('Error loading more messages: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
