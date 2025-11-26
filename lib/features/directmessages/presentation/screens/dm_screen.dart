import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/widgets/adaptive_scaffold.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import 'package:maypole/features/home/presentation/widgets/chat_list_panel.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/maypole_chat_content.dart';
import '../../domain/dm_thread.dart';
import '../widgets/dm_content.dart';
import '../dm_providers.dart';

/// Full-screen wrapper for DM content.
/// Adapts to show split view when rotated to landscape.
class DmScreen extends ConsumerStatefulWidget {
  final DMThread thread;

  const DmScreen({super.key, required this.thread});

  @override
  ConsumerState<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends ConsumerState<DmScreen> {
  late String _currentThreadId;
  late DMThread? _currentDmThread;
  bool _isMaypoleThread = false;
  String _currentMaypoleName = '';

  @override
  void initState() {
    super.initState();
    _currentThreadId = widget.thread.id;
    _currentDmThread = widget.thread;
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

                // Narrow screen: show just the DM content
                return DmContent(thread: widget.thread, showAppBar: true);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: $err')),
          ),
        );
  }

  Widget _buildContentPanel() {
    if (_currentThreadId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isMaypoleThread && _currentMaypoleName.isNotEmpty) {
      return MaypoleChatContent(
        threadId: _currentThreadId,
        maypoleName: _currentMaypoleName,
        showAppBar: false,
      );
    } else if (!_isMaypoleThread && _currentDmThread != null) {
      return DmContent(thread: _currentDmThread!, showAppBar: false);
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
