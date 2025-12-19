import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/data/user_search_service.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';
import 'package:maypole/features/maypolechat/presentation/maypole_chat_providers.dart';

/// Parameters for user search
class UserSearchParams {
  final String threadId;
  final String query;

  const UserSearchParams({
    required this.threadId,
    required this.query,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserSearchParams &&
              runtimeType == other.runtimeType &&
              threadId == other.threadId &&
              query == other.query;

  @override
  int get hashCode => threadId.hashCode ^ query.hashCode;
}

/// Provider for user search service
final userSearchServiceProvider = Provider<UserSearchService>((ref) {
  return UserSearchService();
});

/// Provider for searching users by query (searches locally from loaded messages)
final userSearchProvider = Provider.autoDispose
    .family<List<DomainUser>, UserSearchParams>((ref, params) {
  // Get the messages that are already loaded for this thread
  final messagesAsyncValue = ref.watch(
    maypoleChatViewModelProvider(params.threadId),
  );

  // If messages haven't loaded yet, return empty list
  if (!messagesAsyncValue.hasValue) {
    return [];
  }

  final messages = messagesAsyncValue.value!;
  
  // Extract unique users from the messages
  final Map<String, DomainUser> uniqueUsers = {};
  
  for (var message in messages) {
    // Create a DomainUser from message data
    // Only add if we haven't seen this user yet
    if (!uniqueUsers.containsKey(message.senderId) && 
        message.senderId.isNotEmpty && 
        message.senderName.isNotEmpty) {
      uniqueUsers[message.senderId] = DomainUser(
        firebaseID: message.senderId,
        username: message.senderName,
        email: '', // Email not needed for mention suggestions
        profilePictureUrl: message.senderProfilePictureUrl,
      );
    }
  }

  // If query is empty, return empty list (user hasn't started typing)
  if (params.query.isEmpty) {
    return [];
  }

  // Filter users based on query (fuzzy search - contains)
  final queryLower = params.query.toLowerCase();
  final matchingUsers = uniqueUsers.values
      .where((user) => user.username.toLowerCase().contains(queryLower))
      .toList();

  // Sort by relevance: exact matches first, then starts with, then contains
  matchingUsers.sort((a, b) {
    final aLower = a.username.toLowerCase();
    final bLower = b.username.toLowerCase();
    
    // Exact match
    if (aLower == queryLower) return -1;
    if (bLower == queryLower) return 1;
    
    // Starts with
    final aStarts = aLower.startsWith(queryLower);
    final bStarts = bLower.startsWith(queryLower);
    if (aStarts && !bStarts) return -1;
    if (!aStarts && bStarts) return 1;
    
    // Alphabetical
    return aLower.compareTo(bLower);
  });

  return matchingUsers.take(10).toList();
});

/// State for tracking mentions in a message
class MentionControllerState {
  final List<UserMention> mentions;

  const MentionControllerState({
    this.mentions = const [],
  });

  MentionControllerState copyWith({
    List<UserMention>? mentions,
  }) {
    return MentionControllerState(
      mentions: mentions ?? this.mentions,
    );
  }
}

/// Controller for managing mentions in a message
class MentionController extends Notifier<MentionControllerState> {
  @override
  MentionControllerState build() {
    return const MentionControllerState();
  }

  /// Add a mention to the list
  void addMention(UserMention mention) {
    final mentions = List<UserMention>.from(state.mentions);
    mentions.add(mention);
    state = state.copyWith(mentions: mentions);
  }

  /// Remove a mention from the list
  void removeMention(UserMention mention) {
    final mentions = List<UserMention>.from(state.mentions);
    mentions.remove(mention);
    state = state.copyWith(mentions: mentions);
  }

  /// Clear all mentions
  void clearMentions() {
    state = const MentionControllerState();
  }

  /// Get all user IDs that are mentioned in the current message
  List<String> getMentionedUserIds() {
    return state.mentions.map((m) => m.userId).toSet().toList();
  }

  /// Update mention positions after text changes
  void updateMentionPositions(String text) {
    final updatedMentions = <UserMention>[];

    for (var mention in state.mentions) {
      final mentionText = '@${mention.username}';
      // Check if the mention still exists in the text
      if (text.contains(mentionText)) {
        // Find the position in the current text
        final index = text.indexOf(mentionText);
        if (index != -1) {
          updatedMentions.add(
            UserMention(
              userId: mention.userId,
              username: mention.username,
              startIndex: index,
              endIndex: index + mentionText.length,
            ),
          );
        }
      }
    }

    state = state.copyWith(mentions: updatedMentions);
  }
}

/// Provider for the mention controller
final mentionControllerProvider =
NotifierProvider<MentionController, MentionControllerState>(
      () => MentionController(),
);
