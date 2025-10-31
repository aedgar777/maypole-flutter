import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/chat/data/services/thread_service.dart';
import 'package:maypole/features/chat/presentation/viewmodels/dm_viewmodel.dart';
import 'package:maypole/features/chat/presentation/viewmodels/place_chat_viewmodel.dart';

import 'domain/message.dart';

final threadServiceProvider = Provider<ThreadService>((ref) {
  return ThreadService();
});

final dmViewModelProvider = StateNotifierProvider.autoDispose
    .family<DmViewModel, AsyncValue<List<Message>>, String>((ref, threadId) {
  final threadService = ref.watch(threadServiceProvider);
  return DmViewModel(threadService, threadId);
});

final placeChatViewModelProvider = StateNotifierProvider.autoDispose
    .family<PlaceChatViewModel, AsyncValue<List<Message>>, String>((ref, threadId) {
  final threadService = ref.watch(threadServiceProvider);
  return PlaceChatViewModel(threadService, threadId);
});
