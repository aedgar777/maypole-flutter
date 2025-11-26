import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/widgets/adaptive_scaffold.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/directmessages/presentation/widgets/dm_content.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/maypole_chat_content.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import 'package:maypole/features/settings/settings_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../../../identity/auth_providers.dart';
import '../../../directmessages/presentation/dm_providers.dart';
import '../widgets/chat_list_panel.dart';

/// State for tracking the selected thread in the home screen
class _SelectedThreadState {
  final String? threadId;
  final String? maypoleName;
  final DMThread? dmThread;
  final bool isMaypoleThread;

  const _SelectedThreadState({
    this.threadId,
    this.maypoleName,
    this.dmThread,
    this.isMaypoleThread = true,
  });

  _SelectedThreadState copyWith({
    String? threadId,
    String? maypoleName,
    DMThread? dmThread,
    bool? isMaypoleThread,
  }) {
    return _SelectedThreadState(
      threadId: threadId ?? this.threadId,
      maypoleName: maypoleName ?? this.maypoleName,
      dmThread: dmThread ?? this.dmThread,
      isMaypoleThread: isMaypoleThread ?? this.isMaypoleThread,
    );
  }

  _SelectedThreadState clear() {
    return const _SelectedThreadState();
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _SelectedThreadState _selectedThread = const _SelectedThreadState();
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    // Request notification permissions and initialize FCM after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionsIfNeeded();
      _initializeFcm();
    });
  }

  Future<void> _requestNotificationPermissionsIfNeeded() async {
    // Only request once per session
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    final handler = ref.read(firstTimeNotificationHandlerProvider);

    if (!mounted) return;

    await handler.requestPermissionIfNeeded(context);
  }

  Future<void> _initializeFcm() async {
    try {
      final fcmService = ref.read(fcmServiceProvider);
      await fcmService.initialize();
    } catch (e) {
      // Error is already logged in FcmService
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(authStateProvider)
        .when(
          data: (user) {
            if (user == null) {
              // User is not authenticated, redirect to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/login');
              });
              return const Center(child: CircularProgressIndicator());
            }

            // User is authenticated, show adaptive layout
            return _buildAdaptiveLayout(context, user);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            final l10n = AppLocalizations.of(context)!;
            return Center(child: Text(l10n.error(err.toString())));
          },
        );
  }

  Widget _buildAdaptiveLayout(BuildContext context, DomainUser user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;

        return Scaffold(
          body: AdaptiveScaffold(
            navigationPanel: ChatListPanel(
              user: user,
              selectedThreadId: _selectedThread.threadId,
              isMaypoleThread: _selectedThread.isMaypoleThread,
              onSettingsPressed: () => context.push('/settings'),
              onAddPressed: () => _handleAddPressed(context),
              onMaypoleThreadSelected: (threadId, maypoleName) =>
                  _handleMaypoleThreadSelected(
                    context,
                    threadId,
                    maypoleName,
                    isWideScreen,
                  ),
              onDmThreadSelected: (threadId) =>
                  _handleDmThreadSelected(context, threadId, isWideScreen),
              onTabChanged: () => _handleTabChanged(isWideScreen),
            ),
            contentPanel: _buildContentPanel(),
          ),
          // Only show FAB on mobile screens
          floatingActionButton: isWideScreen
              ? null
              : FloatingActionButton(
            heroTag: 'home_fab',
                  onPressed: () => _handleAddPressed(context),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  void _handleTabChanged(bool isWideScreen) {
    if (isWideScreen) {
      // On wide screen, clear selection when switching tabs
      setState(() {
        _selectedThread = const _SelectedThreadState();
      });
    }
  }

  Widget? _buildContentPanel() {
    if (_selectedThread.threadId == null) {
      return null; // Shows empty state
    }

    if (_selectedThread.isMaypoleThread &&
        _selectedThread.maypoleName != null) {
      return MaypoleChatContent(
        threadId: _selectedThread.threadId!,
        maypoleName: _selectedThread.maypoleName!,
        showAppBar: false,
      );
    } else if (!_selectedThread.isMaypoleThread &&
        _selectedThread.dmThread != null) {
      return DmContent(thread: _selectedThread.dmThread!, showAppBar: false);
    }

    return null;
  }

  Future<void> _handleAddPressed(BuildContext context) async {
    final result = await context.push<PlacePrediction>('/search');

    if (result != null && mounted) {
      final isWideScreen = MediaQuery.of(context).size.width >= 600;

      if (isWideScreen) {
        // On wide screen, update the selected thread to show in the content panel
        setState(() {
          _selectedThread = _SelectedThreadState(
            threadId: result.placeId,
            maypoleName: result.placeName,
            isMaypoleThread: true,
          );
        });
      } else {
        // On mobile, navigate to the chat screen
        if (context.mounted) {
          context.push('/chat/${result.placeId}', extra: result.placeName);
        }
      }
    }
  }

  void _handleMaypoleThreadSelected(
    BuildContext context,
    String threadId,
    String maypoleName,
    bool isWideScreen,
  ) {
    if (isWideScreen) {
      // On wide screen, update the selected thread to show in the content panel
      setState(() {
        _selectedThread = _SelectedThreadState(
          threadId: threadId,
          maypoleName: maypoleName,
          isMaypoleThread: true,
        );
      });
    } else {
      // On mobile, navigate to the chat screen
      context.push('/chat/$threadId', extra: maypoleName);
    }
  }

  Future<void> _handleDmThreadSelected(
    BuildContext context,
    String threadId,
    bool isWideScreen,
  ) async {
    // Fetch the full DM thread
    final dmThread = await ref
        .read(dmThreadServiceProvider)
        .getDMThreadById(threadId);

    if (dmThread != null && mounted) {
      if (isWideScreen) {
        // On wide screen, update the selected thread to show in the content panel
        setState(() {
          _selectedThread = _SelectedThreadState(
            threadId: threadId,
            dmThread: dmThread,
            isMaypoleThread: false,
          );
        });
      } else {
        // On mobile, navigate to the DM screen
        if (context.mounted) {
          context.push('/dm/$threadId', extra: dmThread);
        }
      }
    }
  }
}
