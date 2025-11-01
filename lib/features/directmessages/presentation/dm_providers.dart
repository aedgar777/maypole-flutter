import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/presentation/viewmodels/dm_viewmodel.dart';

import '../domain/direct_message.dart';

final dmThreadServiceProvider = Provider<DMThreadService>((ref) {
  return DMThreadService();
});

final dmViewModelProvider = StateNotifierProvider.autoDispose
    .family<DmViewModel, AsyncValue<List<DirectMessage>>, String>((ref, threadId) {
  final threadService = ref.watch(dmThreadServiceProvider);
  return DmViewModel(threadService, threadId);
});
