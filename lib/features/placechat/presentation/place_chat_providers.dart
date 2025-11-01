import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/placechat/domain/place_chat_message.dart';
import 'package:maypole/features/placechat/data/place_chat_thread_service.dart';
import 'package:maypole/features/placechat/presentation/viewmodels/place_chat_viewmodel.dart';

final placeChatThreadServiceProvider = Provider<PlaceChatThreadService>((ref) {
  return PlaceChatThreadService();
});

final placeChatViewModelProvider = StateNotifierProvider.autoDispose
    .family<PlaceChatViewModel, AsyncValue<List<PlaceChatMessage>>, String>((ref, threadId) {
  final threadService = ref.watch(placeChatThreadServiceProvider);
  return PlaceChatViewModel(threadService, threadId);
});
