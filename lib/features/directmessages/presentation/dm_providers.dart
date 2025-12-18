import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/presentation/viewmodels/dm_viewmodel.dart';
import 'package:maypole/features/identity/auth_providers.dart';

import '../domain/direct_message.dart';
import '../domain/dm_thread.dart';

final dmThreadServiceProvider = Provider<DMThreadService>((ref) {
  return DMThreadService();
});

/// Streams all DM threads for a specific user ID
/// Use this directly in the UI with the current user's ID
final dmThreadsByUserProvider = StreamProvider.family<List<DMThreadMetaData>, String>((ref, userId) {
  // Use ref.read() not ref.watch() to avoid rebuild loops in StreamProvider
  return ref.read(dmThreadServiceProvider).getUserDmThreads(userId);
});

final dmViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<DmViewModel, List<DirectMessage>, String>(
      (threadId) => DmViewModel(threadId),
    );
