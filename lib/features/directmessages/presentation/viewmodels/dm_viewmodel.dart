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

    _init();

    // Return empty list initially, the stream will update it
    return [];
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
    } catch (e) {
      // Log error without using print in production
      developer.log('Error loading more messages: $e', name: 'DmViewModel');
    } finally {
      _isLoadingMore = false;
    }
  }
}

// Provider to hold the threadId parameter
final dmThreadIdProvider = Provider<String>((
    ref) => throw UnimplementedError());
