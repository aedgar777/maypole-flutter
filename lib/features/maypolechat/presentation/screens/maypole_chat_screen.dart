import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/widgets/adaptive_scaffold.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/directmessages/presentation/widgets/dm_content.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import 'package:maypole/features/home/presentation/widgets/chat_list_panel.dart';
import '../widgets/maypole_chat_content.dart';

/// Full-screen wrapper for maypole chat content.
/// Adapts to show split view when rotated to landscape.
class MaypoleChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  final String maypoleName;

  const MaypoleChatScreen({
    super.key,
    required this.threadId,
    required this.maypoleName,
  });

  @override
  ConsumerState<MaypoleChatScreen> createState() => _MaypoleChatScreenState();
}

class _MaypoleChatScreenState extends ConsumerState<MaypoleChatScreen> {
  late String _currentThreadId;
  late String _currentMaypoleName;
  bool _isMaypoleThread = true;
  DMThread? _currentDmThread;

  @override
  void initState() {
    super.initState();
    _currentThreadId = widget.threadId;
    _currentMaypoleName = widget.maypoleName;
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(authStateProvider)
        .when(
          data: (user) {
            if (user == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/login');
              });
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 600;

                if (isWideScreen) {
                  // Wide screen: show adaptive layout with chat list
                  return Scaffold(
                    body: AdaptiveScaffold(
                      navigationPanel: ChatListPanel(
                        user: user,
                        selectedThreadId: _currentThreadId,
                        isMaypoleThread: _isMaypoleThread,
                        onSettingsPressed: () => context.push('/settings'),
                        onAddPressed: () => _handleAddPressed(context),
                        onMaypoleThreadSelected: (threadId, maypoleName) =>
                            _handleMaypoleThreadSelected(threadId, maypoleName),
                        onDmThreadSelected: (threadId) =>
                            _handleDmThreadSelected(threadId),
                        onTabChanged: () => setState(() {
                          // Clear selection when switching tabs
                          _currentThreadId = '';
                        }),
                      ),
                      contentPanel: _buildContentPanel(),
                    ),
                  );
                }

                // Narrow screen: show just the chat content
                // Stay on the current thread (don't navigate back to home)
                if (_isMaypoleThread && _currentMaypoleName.isNotEmpty) {
                  return MaypoleChatContent(
                    threadId: _currentThreadId,
                    maypoleName: _currentMaypoleName,
                    showAppBar: true,
                  );
                } else if (!_isMaypoleThread && _currentDmThread != null) {
                  return DmContent(
                    thread: _currentDmThread!,
                    showAppBar: true,
                  );
                }

                // Fallback to the original thread
                return MaypoleChatContent(
                  threadId: widget.threadId,
                  maypoleName: widget.maypoleName,
                  showAppBar: true,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ErrorDialog.show(context, err);
            });
            return const Center(child: CircularProgressIndicator());
          },
        );
  }

  Widget _buildContentPanel() {
    if (_currentThreadId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isMaypoleThread) {
      return MaypoleChatContent(
        threadId: _currentThreadId,
        maypoleName: _currentMaypoleName,
        showAppBar: false,
        autoFocus: true,
      );
    } else if (_currentDmThread != null) {
      return DmContent(
        thread: _currentDmThread!,
        showAppBar: false,
        autoFocus: true,
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleAddPressed(BuildContext context) async {
    final result = await context.push<PlacePrediction>('/search');
    if (result != null && mounted) {
      // Navigate to the new chat
      if (context.mounted) {
        context.go('/chat/${result.placeId}', extra: result.placeName);
      }
    }
  }

  void _handleMaypoleThreadSelected(String threadId, String maypoleName) {
    setState(() {
      _currentThreadId = threadId;
      _currentMaypoleName = maypoleName;
      _isMaypoleThread = true;
      _currentDmThread = null;
    });
  }

  Future<void> _handleDmThreadSelected(String threadId) async {
    final dmThread = await ref
        .read(dmThreadServiceProvider)
        .getDMThreadById(threadId);

    if (dmThread != null && mounted) {
      setState(() {
        _currentThreadId = threadId;
        _isMaypoleThread = false;
        _currentDmThread = dmThread;
      });
    }
  }
}
