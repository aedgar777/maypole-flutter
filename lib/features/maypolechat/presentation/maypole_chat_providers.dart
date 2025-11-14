import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/maypole_chat_view_model.dart';

import '../data/maypole_chat_service.dart';

final maypoleChatThreadServiceProvider = Provider<MaypoleChatService>((ref) {
  return MaypoleChatService();
});

final maypoleChatViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<MaypoleChatViewModel, List<MaypoleMessage>, String>(
      (threadId) => MaypoleChatViewModel(threadId),
    );
