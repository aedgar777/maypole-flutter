import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/data/user_search_service.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';

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

/// Provider for searching users by query
final userSearchProvider = FutureProvider.autoDispose
    .family<List<DomainUser>, UserSearchParams>((ref, params) async {
  final service = ref.watch(userSearchServiceProvider);
  return service.searchUsersInMaypole(params.threadId, params.query);
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
