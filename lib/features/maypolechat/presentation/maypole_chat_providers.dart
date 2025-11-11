import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/maypole_chat_view_model.dart';

import '../data/maypole_chat_service.dart';

final maypoleChatThreadServiceProvider = Provider<MaypoleChatService>((ref) {
  return MaypoleChatService();
});

final maypoleChatViewModelProvider = StateNotifierProvider.autoDispose
    .family<MaypoleChatViewModel, AsyncValue<List<MaypoleMessage>>, String>((ref, threadId) {
  final threadService = ref.watch(maypoleChatThreadServiceProvider);
  return MaypoleChatViewModel(threadService, threadId);
});
