import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/domain/message.dart';
import '../../../chat/data/services/thread_service.dart';
import '../../../chat/data/services/thread_service_provider.dart';

final dmViewModelProvider = StateNotifierProvider.autoDispose
    .family<DmViewModel, AsyncValue<List<Message>>, String>((ref, threadId) {
  final threadService = ref.watch(threadServiceProvider);
  return DmViewModel(threadService, threadId);
});

class DmViewModel extends StateNotifier<AsyncValue<List<Message>>> {
  final ThreadService _threadService;
  final String _threadId;
  StreamSubscription<List<Message>>? _messagesSubscription;
  bool _isLoadingMore = false;

  DmViewModel(this._threadService, this._threadId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    state = const AsyncValue.loading();
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _threadService.getDmMessages(_threadId).listen((messages) {
      state = AsyncValue.data(messages);
    }, onError: (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  Future<void> sendDmMessage(String body, String sender, String recipient) async {
    try {
      await _threadService.sendDmMessage(_threadId, body, sender, recipient);
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
    } catch (e, st) {
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
