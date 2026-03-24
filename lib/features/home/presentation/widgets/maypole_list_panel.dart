import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/hover_menu_button.dart';
import 'package:maypole/core/widgets/lazy_profile_avatar.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/core/services/profile_picture_cache_service.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/maypolechat/domain/maypole.dart';
import 'package:maypole/features/maypolechat/presentation/maypole_chat_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:maypole/core/ads/widgets/banner_ad_widget.dart';


/// A panel showing the list of maypole chats and DM threads.
/// This widget is used in both mobile and desktop layouts.
class MaypoleListPanel extends ConsumerStatefulWidget {
  final DomainUser user;
  final VoidCallback onSettingsPressed;
  final VoidCallback onAddPressed;
  final Function(String threadId, String maypoleName, String address, double? latitude, double? longitude) onMaypoleThreadSelected;
  final Function(String threadId) onDmThreadSelected;
  final Function(int tabIndex)? onTabChanged;
  final String? selectedThreadId;
  final bool isMaypoleThread;
  final VoidCallback? onThreadDeleted; // Called when current thread is deleted
  final int initialTab; // Initial tab index (0 for Maypoles, 1 for DMs)

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
    this.onThreadDeleted,
    this.initialTab = 0,
  });

  @override
  ConsumerState<MaypoleListPanel> createState() => _MaypoleListPanelState();
}

class _MaypoleListPanelState extends ConsumerState<MaypoleListPanel> with SingleTickerProviderStateMixin {
  // Track threads that are pending deletion (for both maypole and DM threads)
  final Set<String> _pendingDeletions = {};
  final Map<String, Timer> _deletionTimers = {};
  // Track maypole threads pending deletion separately for filtering
  final Set<String> _pendingMaypoleDeletions = {};
  // Track current tab index for FAB animation
  late int _currentTabIndex;
  // Scroll controller for DM list to scroll to selected thread
  final ScrollController _dmScrollController = ScrollController();
  // Track pending scroll target to execute when data loads
  String? _pendingScrollToThreadId;
  // Track DM threads for retry scrolling
  List<DMThreadMetaData>? _lastDmThreads;
  // Retry counter to prevent infinite loops
  int _scrollRetryCount = 0;
  static const int _maxScrollRetries = 20;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    // Store initial selected thread for scrolling
    if (widget.selectedThreadId != null && !widget.isMaypoleThread) {
      _pendingScrollToThreadId = widget.selectedThreadId;
    }
    debugPrint('📋 LIST_PANEL: initState - initialTab=$widget.initialTab, selectedThreadId=${widget.selectedThreadId}, isMaypoleThread=${widget.isMaypoleThread}, pendingScrollTo=$_pendingScrollToThreadId');
  }

  @override
  void dispose() {
    // Cancel all pending timers
    for (var timer in _deletionTimers.values) {
      timer.cancel();
    }
    _deletionTimers.clear();
    _dmScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MaypoleListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    debugPrint('📋 LIST_PANEL: didUpdateWidget - oldSelected=${oldWidget.selectedThreadId}, newSelected=${widget.selectedThreadId}, isMaypoleThread=${widget.isMaypoleThread}');
    
    // If the selected thread changed and it's a DM thread, prepare to scroll to it
    if (widget.selectedThreadId != oldWidget.selectedThreadId &&
        widget.selectedThreadId != null &&
        !widget.isMaypoleThread) {
      debugPrint('📋 LIST_PANEL: Setting pending scroll to ${widget.selectedThreadId}');
      _pendingScrollToThreadId = widget.selectedThreadId;
    }
  }

  /// Execute scroll to selected thread if we have a pending target and data is available
  void _executeScrollToThreadIfNeeded(List<DMThreadMetaData> dmThreads) {
    _lastDmThreads = dmThreads; // Store for retry
    
    debugPrint('📋 LIST_PANEL: _executeScrollToThreadIfNeeded called, pending=$_pendingScrollToThreadId, threadCount=${dmThreads.length}, hasClients=${_dmScrollController.hasClients}');
    
    if (_pendingScrollToThreadId == null) {
      debugPrint('📋 LIST_PANEL: No pending scroll target');
      return;
    }
    
    // Find index of the pending thread
    int? threadIndex;
    for (int i = 0; i < dmThreads.length; i++) {
      if (dmThreads[i].id == _pendingScrollToThreadId) {
        threadIndex = i;
        break;
      }
    }
    
    debugPrint('📋 LIST_PANEL: Found threadIndex=$threadIndex');
    
    if (threadIndex != null) {
      if (_dmScrollController.hasClients) {
        _scrollRetryCount = 0; // Reset retry counter on success
        _performScroll(threadIndex);
      } else {
        // ListView not ready yet, retry after a short delay (with limit)
        _scrollRetryCount++;
        if (_scrollRetryCount > _maxScrollRetries) {
          debugPrint('📋 LIST_PANEL: Max retries reached, giving up on scroll');
          _pendingScrollToThreadId = null;
          _scrollRetryCount = 0;
          return;
        }
        debugPrint('📋 LIST_PANEL: ListView not ready, scheduling retry $_scrollRetryCount/$_maxScrollRetries...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _lastDmThreads != null && _pendingScrollToThreadId != null) {
            _executeScrollToThreadIfNeeded(_lastDmThreads!);
          }
        });
      }
    } else {
      debugPrint('📋 LIST_PANEL: Thread not found in list');
    }
  }
  
  void _performScroll(int threadIndex) {
    // Account for ads in the index calculation (1 ad per 6 threads)
    final adCount = threadIndex ~/ 6;
    final listIndex = threadIndex + adCount;
    
    final maxScroll = _dmScrollController.position.maxScrollExtent;
    const itemHeight = 72.0; // Approximate height of list tile
    final targetOffset = (listIndex * itemHeight).clamp(0.0, maxScroll);
    
    debugPrint('📋 LIST_PANEL: Scrolling to index=$listIndex, offset=$targetOffset');
    
    _dmScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Clear pending scroll after executing
    _pendingScrollToThreadId = null;
    _lastDmThreads = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Cache the userId to prevent provider recreation on every rebuild
    final userId = widget.user.firebaseID;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Builder(
        builder: (context) {
          // Listen for tab changes immediately (not just when animation completes)
          final tabController = DefaultTabController.of(context);
          
          // Check if we need to switch to DM tab for pending scroll
          if (_pendingScrollToThreadId != null && 
              _currentTabIndex == 0 && 
              tabController.index != 1) {
            debugPrint('📋 LIST_PANEL: Animating to DM tab (index 1)');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              tabController.animateTo(1);
            });
          }
          
          tabController.addListener(() {
            // Update immediately when tab changes, even during animation
            final newIndex = tabController.index;
            final isAnimating = tabController.animation?.isAnimating ?? false;
            
            debugPrint('📋 LIST_PANEL: Tab listener - index=$newIndex, isAnimating=$isAnimating, pending=$_pendingScrollToThreadId');
            
            if (_currentTabIndex != newIndex) {
              setState(() {
                _currentTabIndex = newIndex;
              });
              if (widget.onTabChanged != null) {
                widget.onTabChanged!(newIndex);
              }
            }
            
            // If we just switched to DM tab (index 1) and have a pending scroll, try to scroll now
            if (newIndex == 1 && !isAnimating && _pendingScrollToThreadId != null && _dmScrollController.hasClients) {
              debugPrint('📋 LIST_PANEL: Tab animation complete on DM tab, executing scroll');
              // Find thread index from cached threads
              int? threadIndex;
              if (_lastDmThreads != null) {
                for (int i = 0; i < _lastDmThreads!.length; i++) {
                  if (_lastDmThreads![i].id == _pendingScrollToThreadId) {
                    threadIndex = i;
                    break;
                  }
                }
              }
              if (threadIndex != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _performScroll(threadIndex!);
                });
              } else {
                debugPrint('📋 LIST_PANEL: Could not find thread index for scroll');
              }
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
            floatingActionButton: AnimatedScale(
              scale: _currentTabIndex == 0 ? 1.0 : 0.0,
              duration: kTabScrollDuration,
              curve: Curves.ease,
              child: AnimatedOpacity(
                opacity: _currentTabIndex == 0 ? 1.0 : 0.0,
                duration: kTabScrollDuration,
                curve: Curves.ease,
                child: FloatingActionButton(
                  heroTag: 'maypole_list_fab',
                  onPressed: _currentTabIndex == 0 ? widget.onAddPressed : null,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaypoleList(BuildContext context, AppLocalizations l10n) {
    // Filter out maypole threads that are pending deletion and sort by lastTypedAt
    final filteredMaypoleThreads = widget.user.maypoleChatThreads
        .where((thread) => !_pendingMaypoleDeletions.contains(thread.id))
        .toList()
      ..sort((a, b) {
        // Sort by lastTypedAt (most recent first)
        // Threads without lastTypedAt go to the end
        if (a.lastTypedAt == null && b.lastTypedAt == null) return 0;
        if (a.lastTypedAt == null) return 1;
        if (b.lastTypedAt == null) return -1;
        return b.lastTypedAt!.compareTo(a.lastTypedAt!);
      });

    if (filteredMaypoleThreads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(l10n.noPlaceChats, textAlign: TextAlign.center),
        ),
      );
    }

    // Calculate total items including mobile ads only (web ads moved to top)
    int totalItems;
    int adCount;
    
    // Mobile: Banner ads every 6 items (web ads now shown at top of screen)
    adCount = filteredMaypoleThreads.length ~/ 6;
    totalItems = filteredMaypoleThreads.length + adCount;

    return ListView.builder(
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Mobile ads (banner ads every 6 items)
        if (index > 0 && (index + 1) % 7 == 0) {
          return const BannerAdWidget(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          );
        }

        // Calculate the actual thread index (accounting for ads)
        final threadIndex = index - (index ~/ 7);
        if (threadIndex >= filteredMaypoleThreads.length) {
          return const SizedBox.shrink();
        }
        
        final thread = filteredMaypoleThreads[threadIndex];
        return _buildMaypoleListTile(context, thread);
      },
    );
  }

  Widget _buildMaypoleListTile(BuildContext context, MaypoleMetaData thread) {
    final isSelected = widget.selectedThreadId == thread.id && widget.isMaypoleThread;
    
    return HoverListTile(
      tileColor: isSelected ? Colors.grey.withValues(alpha: 0.15) : null,
      leading: const Icon(Icons.location_on),
      title: Text(
        thread.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: thread.address.isNotEmpty
          ? Text(
              thread.address,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            )
          : null,
      onTap: () {
        widget.onMaypoleThreadSelected(
          thread.id, 
          thread.name, 
          thread.address,
          thread.latitude,
          thread.longitude,
        );
      },
      onMenuTap: (triggerContext) {
        _showMaypoleThreadContextMenu(
          context,
          thread,
          widget.user.firebaseID,
          triggerContext,
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

        // Prefetch profile pictures for all visible users in background
        // This makes avatars load instantly as user scrolls
        final partnerIds = filteredDmThreads.map((thread) => thread.partnerId).toList();
        ref.read(profilePictureCacheServiceProvider).prefetchProfilePictures(partnerIds);

        // Calculate total items including ads (1 ad per 6 threads) for mobile
        final adCount = filteredDmThreads.length ~/ 6;
        final totalItems = filteredDmThreads.length + adCount;

        // Try to scroll to selected thread after data loads and list builds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _executeScrollToThreadIfNeeded(filteredDmThreads);
        });

        return ListView.builder(
          controller: _dmScrollController,
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // Show ad every 6 items (at positions 6, 13, 20, etc.) - mobile only
            if (index > 0 && (index + 1) % 7 == 0) {
              return const BannerAdWidget(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              );
            }

            // Calculate the actual thread index (accounting for ads)
            final threadIndex = index - (index ~/ 7);
            if (threadIndex >= filteredDmThreads.length) {
              return const SizedBox.shrink();
            }

            final threadMetadata = filteredDmThreads[index];
            final isSelected =
                widget.selectedThreadId == threadMetadata.id && !widget.isMaypoleThread;
            final formattedTimestamp = DateTimeUtils.formatThreadTimestamp(
              threadMetadata.lastMessageTime,
            );
            
            // Build subtitle text with last message preview
            final subtitleText = threadMetadata.lastMessageBody != null && threadMetadata.lastMessageBody!.isNotEmpty
                ? '$formattedTimestamp • ${threadMetadata.lastMessageBody}'
                : formattedTimestamp;

            return HoverListTile(
              tileColor: isSelected ? Colors.grey.withValues(alpha: 0.15) : null,
              leading: Stack(
                children: [
                  LazyProfileAvatar(
                    userId: threadMetadata.partnerId,
                    initialProfilePictureUrl: threadMetadata.partnerProfpic,
                  ),
                  // Unread indicator badge
                  if (threadMetadata.hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                threadMetadata.partnerName,
                style: TextStyle(
                  fontWeight: threadMetadata.hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                subtitleText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: threadMetadata.hasUnread ? 0.9 : 0.5),
                  fontWeight: threadMetadata.hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                widget.onDmThreadSelected(threadMetadata.id);
              },
              onMenuTap: (triggerContext) {
                _showThreadContextMenu(
                  context,
                  threadMetadata,
                  userId,
                  triggerContext,
                );
              },
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
                    color: Colors.white.withValues(alpha: 0.7),
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
    BuildContext triggerContext,
  ) {
    // Web: show menu at trigger position. Mobile: use long-press + bottom sheet.
    if (kIsWeb) {
      // Desktop: Show menu at the position of the 3-dot button
      final RenderBox? renderBox = triggerContext.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx + size.width,
            position.dy,
            position.dx + size.width + 200,
            position.dy + size.height,
          ),
          items: [
            PopupMenuItem(
              onTap: () => _showDeleteSnackbar(context, threadMetadata, userId),
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
        return;
      }
    }

    // Mobile: Use bottom sheet (existing behavior)
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.cancel),
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

    // Notify parent if this is the currently selected thread
    if (widget.selectedThreadId == threadMetadata.id && widget.onThreadDeleted != null) {
      widget.onThreadDeleted!();
    }

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
          final l10n = AppLocalizations.of(context)!;
          AppToast.showError(context, l10n.errorDeletingMessage(e.toString()));
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

    final l10n = AppLocalizations.of(context)!;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(l10n.messageDeleted),
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
              SnackBar(
                content: Text(l10n.deletionCancelled),
                duration: const Duration(seconds: 2),
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
    BuildContext triggerContext,
  ) {
    // Web: show menu at trigger position. Mobile: use long-press + bottom sheet.
    if (kIsWeb) {
      // Desktop: Show menu at the position of the 3-dot button
      final RenderBox? renderBox = triggerContext.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx + size.width,
            position.dy,
            position.dx + size.width + 200,
            position.dy + size.height,
          ),
          items: [
            PopupMenuItem(
              onTap: () => _showMaypoleDeleteSnackbar(context, threadMetadata, userId),
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
        return;
      }
    }

    // Mobile: Use bottom sheet (existing behavior)
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.cancel),
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

    // Notify parent if this is the currently selected thread
    if (widget.selectedThreadId == threadMetadata.id && widget.onThreadDeleted != null) {
      widget.onThreadDeleted!();
    }

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
          final l10n = AppLocalizations.of(context)!;
          AppToast.showError(context, l10n.errorDeletingConversation(e.toString()));
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

    final l10n = AppLocalizations.of(context)!;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(l10n.conversationDeleted),
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
              SnackBar(
                content: Text(l10n.deletionCancelled),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
