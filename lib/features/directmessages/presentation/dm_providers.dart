import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/data/dm_message_preloader.dart';
import 'package:maypole/features/directmessages/data/dm_image_service.dart';
import 'package:maypole/features/directmessages/presentation/viewmodels/dm_viewmodel.dart';

import '../domain/direct_message.dart';
import '../domain/dm_thread.dart';

final dmThreadServiceProvider = Provider<DMThreadService>((ref) {
  return DMThreadService();
});

final dmImageServiceProvider = Provider<DmImageService>((ref) {
  return DmImageService();
});

/// Global DM message preloader that loads all DM messages in the background
/// This ensures instant message display when opening any DM thread
final dmMessagePreloaderProvider = Provider<DmMessagePreloader>((ref) {
  final dmThreadService = ref.watch(dmThreadServiceProvider);
  final preloader = DmMessagePreloader(dmThreadService, ref);
  
  ref.onDispose(() {
    preloader.dispose();
  });
  
  return preloader;
});

/// Streams all DM threads for a specific user ID
/// Use this directly in the UI with the current user's ID
final dmThreadsByUserProvider = StreamProvider.family<List<DMThreadMetaData>, String>((ref, userId) {
  // Use ref.read() not ref.watch() to avoid rebuild loops in StreamProvider
  return ref.read(dmThreadServiceProvider).getUserDmThreads(userId);
});

/// DM View Model provider without autoDispose to maintain cache
/// This keeps the stream subscription alive and reduces Firestore reads
/// when navigating back to previously viewed DM threads
final dmViewModelProvider = AsyncNotifierProvider
    .family<DmViewModel, List<DirectMessage>, String>(
      (threadId) => DmViewModel(threadId),
    );
