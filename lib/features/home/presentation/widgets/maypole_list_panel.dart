import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/maypolechat/domain/maypole.dart';
import 'package:maypole/features/maypolechat/presentation/maypole_chat_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

/// A panel showing the list of maypole chats and DM threads.
/// This widget is used in both mobile and desktop layouts.
class MaypoleListPanel extends ConsumerStatefulWidget {
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
  ConsumerState<MaypoleListPanel> createState() => _MaypoleListPanelState();
}

class _MaypoleListPanelState extends ConsumerState<MaypoleListPanel> {
  // Track threads that are pending deletion (for both maypole and DM threads)
  final Set<String> _pendingDeletions = {};
  final Map<String, Timer> _deletionTimers = {};
  // Track maypole threads pending deletion separately for filtering
  final Set<String> _pendingMaypoleDeletions = {};

  @override
  void dispose() {
    // Cancel all pending timers
    for (var timer in _deletionTimers.values) {
      timer.cancel();
    }
    _deletionTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Cache the userId to prevent provider recreation on every rebuild
    final userId = widget.user.firebaseID;

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          // Listen for tab changes
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging && widget.onTabChanged != null) {
              widget.onTabChanged!();
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
                  onPressed: widget.onSettingsPressed,
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
                _buildDmList(context, l10n, userId),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'maypole_list_fab',
              onPressed: widget.onAddPressed,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaypoleList(BuildContext context, AppLocalizations l10n) {
    // Filter out maypole threads that are pending deletion
    final filteredMaypoleThreads = widget.user.maypoleChatThreads
        .where((thread) => !_pendingMaypoleDeletions.contains(thread.id))
        .toList();

    if (filteredMaypoleThreads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(l10n.noPlaceChats, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMaypoleThreads.length,
      itemBuilder: (context, index) {
        final thread = filteredMaypoleThreads[index];
        final isSelected = widget.selectedThreadId == thread.id && widget.isMaypoleThread;

        return Material(
          color: Colors.transparent,
          child: ListTile(
            selected: isSelected,
            selectedTileColor: Colors.grey.withValues(alpha: 0.15),
            leading: const Icon(Icons.location_on),
            title: Text(thread.name),
            onTap: () => widget.onMaypoleThreadSelected(thread.id, thread.name),
            onLongPress: () {
              _showMaypoleThreadContextMenu(
                context,
                thread,
                widget.user.firebaseID,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDmList(
    BuildContext context,
    AppLocalizations l10n,
    String userId,
  ) {
    // Watch the DM threads stream for this specific user
    final dmThreadsAsync = ref.watch(dmThreadsByUserProvider(userId));

    return dmThreadsAsync.when(
      data: (dmThreads) {
        // Filter out DM threads with blocked users and pending deletions
        final blockedUserIds = widget.user.blockedUsers
            .map((user) => user.firebaseId)
            .toSet();
        final filteredDmThreads = dmThreads
            .where((thread) => 
              !blockedUserIds.contains(thread.partnerId) &&
              !_pendingDeletions.contains(thread.id))
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
                widget.selectedThreadId == threadMetadata.id && !widget.isMaypoleThread;
            final formattedTimestamp = DateTimeUtils.formatThreadTimestamp(
              threadMetadata.lastMessageTime,
            );

            return Material(
              color: Colors.transparent,
              child: ListTile(
                selected: isSelected,
                selectedTileColor: Colors.grey.withValues(alpha: 0.15),
                leading: CachedProfileAvatar(imageUrl: threadMetadata.partnerProfpic),
                title: Text(threadMetadata.partnerName),
                subtitle: Text(
                  formattedTimestamp,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                onTap: () => widget.onDmThreadSelected(threadMetadata.id),
                onLongPress: () {
                  _showThreadContextMenu(
                    context,
                    threadMetadata,
                    userId,
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('❌ DM List Error: $error');
        debugPrint('Stack trace: $stack');
        
        // Check if this is a Firestore index error
        final errorMsg = error.toString();
        final isIndexError = errorMsg.contains('index') || 
                            errorMsg.contains('FAILED_PRECONDITION');
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  isIndexError 
                    ? 'Database index required\n\nCheck the console for a link to create the missing Firestore index.'
                    : 'Error loading DMs',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThreadContextMenu(
    BuildContext context,
    DMThreadMetaData threadMetadata,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Conversation',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteSnackbar(
                    context,
                    threadMetadata,
                    userId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSnackbar(
    BuildContext context,
    DMThreadMetaData threadMetadata,
    String userId,
  ) {
    // Mark thread as pending deletion
    setState(() {
      _pendingDeletions.add(threadMetadata.id);
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Schedule deletion after 3 seconds
    final timer = Timer(const Duration(seconds: 3), () async {
      _deletionTimers.remove(threadMetadata.id);
      
      try {
        await ref.read(dmThreadServiceProvider).deleteDMThreadForUser(
          threadMetadata.id,
          userId,
        );
        
        // Dismiss the snackbar after successful deletion
        scaffoldMessenger.hideCurrentSnackBar();
      } catch (e) {
        // If deletion fails, show error message and restore the thread
        setState(() {
          _pendingDeletions.remove(threadMetadata.id);
        });
        
        // Hide the original snackbar before showing error
        scaffoldMessenger.hideCurrentSnackBar();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Clean up pending deletion state after actual deletion
        if (mounted) {
          setState(() {
            _pendingDeletions.remove(threadMetadata.id);
          });
        }
      }
    });
    
    _deletionTimers[threadMetadata.id] = timer;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Message deleted'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Cancel the deletion timer
            _deletionTimers[threadMetadata.id]?.cancel();
            _deletionTimers.remove(threadMetadata.id);
            
            // Remove from pending deletions to restore in list
            setState(() {
              _pendingDeletions.remove(threadMetadata.id);
            });
            
            // Show confirmation
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Deletion cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMaypoleThreadContextMenu(
    BuildContext context,
    MaypoleMetaData threadMetadata,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Conversation',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showMaypoleDeleteSnackbar(
                    context,
                    threadMetadata,
                    userId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaypoleDeleteSnackbar(
    BuildContext context,
    MaypoleMetaData threadMetadata,
    String userId,
  ) {
    // Mark thread as pending deletion
    setState(() {
      _pendingMaypoleDeletions.add(threadMetadata.id);
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Schedule deletion after 3 seconds
    final timer = Timer(const Duration(seconds: 3), () async {
      _deletionTimers.remove(threadMetadata.id);
      
      try {
        await ref.read(maypoleChatThreadServiceProvider).deleteMaypoleThreadForUser(
          threadMetadata.id,
          userId,
        );
        
        // Dismiss the snackbar after successful deletion
        scaffoldMessenger.hideCurrentSnackBar();
      } catch (e) {
        // If deletion fails, show error message and restore the thread
        setState(() {
          _pendingMaypoleDeletions.remove(threadMetadata.id);
        });
        
        // Hide the original snackbar before showing error
        scaffoldMessenger.hideCurrentSnackBar();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting conversation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Clean up pending deletion state after actual deletion
        if (mounted) {
          setState(() {
            _pendingMaypoleDeletions.remove(threadMetadata.id);
          });
        }
      }
    });
    
    _deletionTimers[threadMetadata.id] = timer;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Conversation deleted'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Cancel the deletion timer
            _deletionTimers[threadMetadata.id]?.cancel();
            _deletionTimers.remove(threadMetadata.id);
            
            // Remove from pending deletions to restore in list
            setState(() {
              _pendingMaypoleDeletions.remove(threadMetadata.id);
            });
            
            // Show confirmation
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Deletion cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
