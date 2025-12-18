import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

/// A panel showing the list of maypole chats and DM threads.
/// This widget is used in both mobile and desktop layouts.
class MaypoleListPanel extends ConsumerWidget {
  final DomainUser user;
  final VoidCallback onSettingsPressed;
  final VoidCallback onAddPressed;
  final Function(String threadId, String maypoleName) onMaypoleThreadSelected;
  final Function(String threadId) onDmThreadSelected;
  final VoidCallback? onTabChanged;
  final String? selectedThreadId;
  final bool isMaypoleThread;

  const MaypoleListPanel({
    super.key,
    required this.user,
    required this.onSettingsPressed,
    required this.onAddPressed,
    required this.onMaypoleThreadSelected,
    required this.onDmThreadSelected,
    this.onTabChanged,
    this.selectedThreadId,
    this.isMaypoleThread = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    // Cache the userId to prevent provider recreation on every rebuild
    final userId = user.firebaseID;

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          // Listen for tab changes
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging && onTabChanged != null) {
              onTabChanged!();
            }
          });

          return Scaffold(
            appBar: AppBar(
              // Remove back button on wide screens
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: l10n.settings,
                  onPressed: onSettingsPressed,
                ),
              ],
              bottom: TabBar(
                dividerColor: Colors.white.withAlpha(26),
                tabs: [
                  Tab(text: l10n.maypolesTab),
                  Tab(text: l10n.directMessagesTab),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildMaypoleList(context, l10n),
                _buildDmList(context, ref, l10n, userId),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'maypole_list_fab',
              onPressed: onAddPressed,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaypoleList(BuildContext context, AppLocalizations l10n) {
    if (user.maypoleChatThreads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(l10n.noPlaceChats, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      itemCount: user.maypoleChatThreads.length,
      itemBuilder: (context, index) {
        final thread = user.maypoleChatThreads[index];
        final isSelected = selectedThreadId == thread.id && isMaypoleThread;

        return ListTile(
          selected: isSelected,
          selectedTileColor: Colors.grey.withValues(alpha: 0.15),
          leading: const Icon(Icons.location_on),
          title: Text(thread.name),
          onTap: () {
            // Allow the ripple animation to complete before navigating
            Future.microtask(() => onMaypoleThreadSelected(thread.id, thread.name));
          },
        );
      },
    );
  }

  Widget _buildDmList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String userId,
  ) {
    // Watch the DM threads stream for this specific user
    final dmThreadsAsync = ref.watch(dmThreadsByUserProvider(userId));

    return dmThreadsAsync.when(
      data: (dmThreads) {
        // Filter out DM threads with blocked users
        final blockedUserIds = user.blockedUsers
            .map((user) => user.firebaseId)
            .toSet();
        final filteredDmThreads = dmThreads
            .where((thread) => !blockedUserIds.contains(thread.partnerId))
            .toList();

        if (filteredDmThreads.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(l10n.noDirectMessages, textAlign: TextAlign.center),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDmThreads.length,
          itemBuilder: (context, index) {
            final threadMetadata = filteredDmThreads[index];
            final isSelected =
                selectedThreadId == threadMetadata.id && !isMaypoleThread;
            final formattedDateTime = DateTimeUtils.formatRelativeDateTime(
              threadMetadata.lastMessageTime,
              context: context,
            );

            return ListTile(
              selected: isSelected,
              selectedTileColor: Colors.grey.withValues(alpha: 0.15),
              leading: CachedProfileAvatar(imageUrl: threadMetadata.partnerProfpic),
              title: Text(threadMetadata.partnerName),
              subtitle: Text(l10n.lastMessage(formattedDateTime)),
              onTap: () {
                // Allow the ripple animation to complete before navigating
                Future.microtask(() => onDmThreadSelected(threadMetadata.id));
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading DMs: $error', textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}
