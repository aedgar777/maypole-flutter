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

/// Notifier for ephemeral (unsaved) DM threads.
class EphemeralDmThreadsNotifier extends Notifier<List<DMThread>> {
  @override
  List<DMThread> build() => [];

  void addThread(DMThread thread) {
    if (!state.any((t) => t.id == thread.id)) {
      state = [...state, thread];
    }
  }

  void removeThread(String threadId) {
    state = state.where((t) => t.id != threadId).toList();
  }
}

/// Provider for ephemeral (unsaved) DM threads.
final ephemeralDmThreadsProvider =
    NotifierProvider<EphemeralDmThreadsNotifier, List<DMThread>>(
  EphemeralDmThreadsNotifier.new,
);

/// Streams all DM threads for a specific user ID, including ephemeral threads
/// Ephemeral threads are merged with Firestore threads for the UI
final dmThreadsByUserProvider = StreamProvider.family<List<DMThreadMetaData>, String>((ref, userId) {
  // Use ref.read() not ref.watch() to avoid rebuild loops in StreamProvider
  final firestoreStream = ref.read(dmThreadServiceProvider).getUserDmThreads(userId);
  
  // Combine with ephemeral threads
  return firestoreStream.map((firestoreThreads) {
    final ephemeralThreads = ref.read(ephemeralDmThreadsProvider);
    
    // Convert ephemeral DMThreads to DMThreadMetaData
    final ephemeralMetadata = ephemeralThreads.map((thread) {
      // Find the other participant (not the current user)
      final otherParticipantId = thread.participantIds.firstWhere(
        (id) => id != userId,
        orElse: () => thread.participantIds.first,
      );
      final otherParticipant = thread.participants[otherParticipantId];
      
      return DMThreadMetaData(
        id: thread.id,
        name: thread.id,
        lastMessageTime: thread.lastMessageTime,
        partnerName: otherParticipant?.username ?? 'Unknown',
        partnerId: otherParticipantId,
        partnerProfpic: otherParticipant?.profilePicUrl ?? '',
        lastMessageBody: thread.lastMessage?.body,
        hasUnread: thread.unreadBy[userId] ?? false,
      );
    }).toList();
    
    // Merge and sort by lastMessageTime (newest first)
    final List<DMThreadMetaData> allThreads = [...firestoreThreads, ...ephemeralMetadata];
    allThreads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    return allThreads;
  });
});

/// DM View Model provider without autoDispose to maintain cache
/// This keeps the stream subscription alive and reduces Firestore reads
/// when navigating back to previously viewed DM threads
final dmViewModelProvider = AsyncNotifierProvider
    .family<DmViewModel, List<DirectMessage>, String>(
      (threadId) => DmViewModel(threadId),
    );
