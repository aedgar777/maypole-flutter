import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/presentation/viewmodels/dm_viewmodel.dart';

import '../domain/direct_message.dart';

final dmThreadServiceProvider = Provider<DMThreadService>((ref) {
  return DMThreadService();
});

final dmViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<DmViewModel, List<DirectMessage>, String>(
      (threadId) => DmViewModel(threadId),
    );
