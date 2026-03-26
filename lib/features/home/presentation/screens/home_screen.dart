import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/services/prefetch_service_provider.dart';
import 'package:maypole/core/services/remote_config_provider.dart';
import 'package:maypole/core/widgets/adaptive_scaffold.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/directmessages/presentation/widgets/dm_content.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/maypole_chat_content.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import 'package:maypole/features/maypolesearch/presentation/screens/maypole_search_screen.dart';
import 'package:maypole/features/settings/settings_providers.dart';
import 'package:maypole/core/ads/widgets/interstitial_ad_manager.dart';
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';
import 'package:maypole/core/ads/ad_config.dart';
import 'package:maypole/core/ads/ad_providers.dart';
import 'package:maypole/core/services/permissions_provider.dart';
import 'package:maypole/core/utils/screen_utils.dart';
import '../../../identity/auth_providers.dart';
import '../../../directmessages/presentation/dm_providers.dart';
import '../../../maypolechat/presentation/maypole_chat_providers.dart';
import '../widgets/maypole_list_panel.dart';

/// State for tracking the selected thread in the home screen
class _SelectedThreadState {
  final String? threadId;
  final String? maypoleName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DMThread? dmThread;
  final bool isMaypoleThread;

  const _SelectedThreadState({
    this.threadId,
    this.maypoleName,
    this.address,
    this.latitude,
    this.longitude,
    this.dmThread,
    this.isMaypoleThread = true,
  });

  _SelectedThreadState copyWith({
    String? threadId,
    String? maypoleName,
    String? address,
    double? latitude,
    double? longitude,
    DMThread? dmThread,
    bool? isMaypoleThread,
  }) {
    return _SelectedThreadState(
      threadId: threadId ?? this.threadId,
      maypoleName: maypoleName ?? this.maypoleName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dmThread: dmThread ?? this.dmThread,
      isMaypoleThread: isMaypoleThread ?? this.isMaypoleThread,
    );
  }

  _SelectedThreadState clear() {
    return const _SelectedThreadState();
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  final int? initialTab;
  final String? selectedDmThreadId;
  final DMThread? selectedDmThread;

  const HomeScreen({
    super.key,
    this.initialTab,
    this.selectedDmThreadId,
    this.selectedDmThread,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Duration _searchScreenKeepAliveTtl = Duration(hours: 1);

  _SelectedThreadState _selectedThread = const _SelectedThreadState();
  bool _hasRequestedPermissions = false;
  bool _hasPrefetchedData = false;
  int _currentTabIndex = 0;
  int _threadSwitchCount = 0; // Track thread switches for interstitial ads
  // Flag to track if tab change was programmatic (from navigation) vs user tap
  bool _isProgrammaticTabChange = false;
  bool _isSearchOverlayVisible = false;
  bool _shouldKeepSearchScreenMounted = false;
  Timer? _searchOverlayDisposeTimer;
  Completer<PlacePrediction?>? _searchOverlayCompleter;
  LocalHistoryEntry? _searchOverlayHistoryEntry;
  bool _isRemovingSearchOverlayHistoryEntry = false;

  @override
  void initState() {
    super.initState();
    // Initialize tab index from widget parameter, default to 0
    _currentTabIndex = widget.initialTab ?? 0;

    // If navigating to a specific tab (like DM tab from notification/profile),
    // mark it as programmatic so we don't clear the selection
    if (widget.initialTab != null && widget.initialTab != 0) {
      _isProgrammaticTabChange = true;
    }

    // Initialize selected thread from widget parameter if provided
    _initializeFromWidgetParams();

    // Request permissions and initialize services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRemoteConfig();
      _initializeAds();
      _requestPermissionsIfNeeded();
      _initializeFcm();
      _prefetchUserDataIfNeeded();
      _checkEmailVerificationIfNeeded();
      _initializeDmPreloader();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle when navigation passes new parameters (e.g., from profile screen DM button)
    if (widget.initialTab != oldWidget.initialTab ||
        widget.selectedDmThreadId != oldWidget.selectedDmThreadId) {
      // Check if this is a programmatic tab change
      if (widget.initialTab != null &&
          widget.initialTab != oldWidget.initialTab &&
          widget.initialTab != 0) {
        _isProgrammaticTabChange = true;
      }

      setState(() {
        _currentTabIndex = widget.initialTab ?? 0;
        _initializeFromWidgetParams();
      });
    }
  }

  @override
  void dispose() {
    _searchOverlayDisposeTimer?.cancel();
    _removeSearchOverlayHistoryEntry();
    super.dispose();
  }

  void _initializeFromWidgetParams() {
    if (widget.selectedDmThreadId != null && widget.selectedDmThread != null) {
      final dmThread = widget.selectedDmThread as DMThread;
      _selectedThread = _SelectedThreadState(
        threadId: widget.selectedDmThreadId,
        dmThread: dmThread,
        isMaypoleThread: false,
      );
    }
  }

  /// Initialize Firebase Remote Config in the background
  /// This loads feature flags for ads and other remote-controlled features
  Future<void> _initializeRemoteConfig() async {
    try {
      final remoteConfig = ref.read(remoteConfigServiceProvider);
      await remoteConfig.initialize();
    } catch (e) {
      debugPrint('⚠️ Warning: Could not initialize Remote Config: $e');
      // Continue anyway - will use default values
    }
  }

  /// Initialize AdMob SDK in the background
  /// This enables ads throughout the app after user has logged in
  Future<void> _initializeAds() async {
    try {
      final adService = ref.read(adServiceProvider);
      await adService.initialize();
      ref.read(adInitializedProvider.notifier).setInitialized(true);
    } catch (e) {
      debugPrint('⚠️ Warning: Could not initialize AdMob: $e');
      // Continue anyway - app will work without ads
    }
  }

  /// Initialize the global DM message preloader
  /// This loads all DM messages in the background for instant access
  Future<void> _initializeDmPreloader() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user == null) return;

    try {
      final preloader = ref.read(dmMessagePreloaderProvider);
      await preloader.preloadAllDmThreads(user.firebaseID);
    } catch (e) {
      debugPrint('⚠️ Error initializing DM preloader: $e');
    }
  }

  Future<void> _requestPermissionsIfNeeded() async {
    // Only request once per session
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    final handler = ref.read(firstTimePermissionsHandlerProvider);

    if (!mounted) return;

    await handler.requestPermissionsIfNeeded(context);
  }

  Future<void> _initializeFcm() async {
    if (kIsWeb) {
      // Web push requires valid firebase-messaging-sw.js hosting; skip noisy init here.
      return;
    }
    try {
      final fcmService = ref.read(fcmServiceProvider);
      await fcmService.initialize();
    } catch (e) {
      // Error is already logged in FcmService
    }
  }

  /// Prefetches user data on app start/resume to warm up the cache
  /// This runs in background and doesn't block the UI
  Future<void> _prefetchUserDataIfNeeded() async {
    // Only prefetch once per session
    if (_hasPrefetchedData) return;
    _hasPrefetchedData = true;

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user == null) return;

    try {
      final prefetchService = ref.read(userDataPrefetchServiceProvider);
      // Run in background without blocking UI
      prefetchService.prefetchUserData(user.firebaseID).catchError((e) {
        debugPrint('⚠️ Background prefetch failed (non-critical): $e');
      });
    } catch (e) {
      debugPrint('⚠️ Error starting prefetch: $e');
    }
  }

  /// Check email verification status when the app starts
  /// This ensures the verification status is up-to-date
  Future<void> _checkEmailVerificationIfNeeded() async {
    try {
      final authService = ref.read(authServiceProvider);
      // Run in background to check and update verification status
      authService.checkEmailVerificationStatus().catchError((e) {
        debugPrint('⚠️ Email verification check failed (non-critical): $e');
      });
    } catch (e) {
      debugPrint('⚠️ Error checking email verification: $e');
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ErrorDialog.show(context, err);
            });
            return const Center(child: CircularProgressIndicator());
          },
        );
  }

  Widget _buildAdaptiveLayout(BuildContext context, DomainUser user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = ScreenUtils.isWideScreen(constraints);

        // Handle transition from wide to narrow screen with a selected thread
        if (!isWideScreen && _selectedThread.threadId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedThread.threadId != null) {
              if (_selectedThread.isMaypoleThread &&
                  _selectedThread.maypoleName != null) {
                // Navigate to maypole chat screen
                context.go(
                  '/chat/${_selectedThread.threadId}',
                  extra: _selectedThread.maypoleName,
                );
              } else if (!_selectedThread.isMaypoleThread &&
                  _selectedThread.dmThread != null) {
                // Navigate to DM screen
                context.go('/dm/${_selectedThread.threadId}',
                    extra: _selectedThread.dmThread);
              }
            }
          });
        }

        final shouldShowAddFab = _currentTabIndex == 0 && !_isSearchOverlayVisible;

        return PopScope(
          canPop: !_isSearchOverlayVisible,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_isSearchOverlayVisible) {
              _closeSearchOverlay();
            }
          },
          child: Scaffold(
            body: Stack(
              children: [
                AdaptiveScaffold(
                  navigationPanel: MaypoleListPanel(
                    user: user,
                    selectedThreadId: _selectedThread.threadId,
                    isMaypoleThread: _selectedThread.isMaypoleThread,
                    onSettingsPressed: () => context.push('/settings'),
                    onAddPressed: () => _handleAddPressed(context),
                    onMaypoleThreadSelected: (threadId, maypoleName, address, latitude, longitude) =>
                        _handleMaypoleThreadSelected(
                          context,
                          threadId,
                          maypoleName,
                          address,
                          latitude,
                          longitude,
                          isWideScreen,
                        ),
                    onDmThreadSelected: (threadId) =>
                        _handleDmThreadSelected(context, threadId, isWideScreen),
                    onTabChanged: (tabIndex) => _handleTabChanged(tabIndex, isWideScreen),
                    onThreadDeleted: () {
                      // Clear selection when current thread is deleted
                      setState(() {
                        _selectedThread = const _SelectedThreadState();
                      });
                    },
                  ),
                  contentPanel: _buildContentPanel(),
                ),
                if (_shouldKeepSearchScreenMounted)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_isSearchOverlayVisible,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isSearchOverlayVisible ? 1 : 0,
                        child: MaypoleSearchScreen(
                          embedded: true,
                          onCloseRequested: _closeSearchOverlay,
                          onPlaceSelected: _onSearchPlaceSelected,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Only show scaffold FAB on narrow/mobile layout.
            // Wide/web layout already has the add FAB in the list panel.
            floatingActionButton: isWideScreen
                ? null
                : AnimatedScale(
                    scale: shouldShowAddFab ? 1.0 : 0.0,
                    duration: kTabScrollDuration,
                    curve: Curves.ease,
                    child: AnimatedOpacity(
                      opacity: shouldShowAddFab ? 1.0 : 0.0,
                      duration: kTabScrollDuration,
                      curve: Curves.ease,
                      child: FloatingActionButton(
                        heroTag: 'home_fab',
                        onPressed: shouldShowAddFab ? () => _handleAddPressed(context) : null,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _handleTabChanged(int tabIndex, bool isWideScreen) {
    setState(() {
      _currentTabIndex = tabIndex;
      if (isWideScreen && !_isProgrammaticTabChange) {
        // On wide screen, clear selection when switching tabs
        // BUT only if this was a user tap (not programmatic navigation)
        _selectedThread = const _SelectedThreadState();
      }
    });
    
    // Reset the flag after handling
    if (_isProgrammaticTabChange) {
      _isProgrammaticTabChange = false;
    }
  }

  Widget? _buildContentPanel() {
    if (_selectedThread.threadId == null) {
      return null; // Shows empty state
    }

    if (_selectedThread.isMaypoleThread &&
        _selectedThread.maypoleName != null) {
      // Build the maypole chat content
      final chatContent = MaypoleChatContent(
        threadId: _selectedThread.threadId!,
        maypoleName: _selectedThread.maypoleName!,
        address: _selectedThread.address,
        latitude: _selectedThread.latitude,
        longitude: _selectedThread.longitude,
        showAppBar: false,
        autoFocus: true,
        showWebAd: false, // Hide ad since we'll show it with share buttons in the header
      );

      // On web/wide screen, add share and gallery icons in the gradient header above the ad
      if (kIsWeb || AppConfig.isWideScreen) {
        return Column(
          children: [
            // Web header with gradient background - share/gallery buttons and ad in same row
            if (kIsWeb && AdConfig.webAdsEnabled)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Centered ad
                    Center(
                      child: WebHorizontalBannerAd(
                        adSlot: AdConfig.adsterraLeaderboardSlot,
                        adKey: AdConfig.adsterraLeaderboardKey,
                      ),
                    ),
                    // Share and gallery buttons in top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white70),
                            onPressed: () => _shareMaypoleConversation(context),
                            tooltip: 'Share conversation',
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.white70),
                            onPressed: () {
                              context.push(
                                '/chat/${_selectedThread.threadId}/gallery?name=${Uri.encodeComponent(_selectedThread.maypoleName!)}',
                              );
                            },
                            tooltip: 'View gallery',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // If no ad, just show share/gallery buttons in a simple header
            if (kIsWeb && !AdConfig.webAdsEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareMaypoleConversation(context),
                      tooltip: 'Share conversation',
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () {
                        context.push(
                          '/chat/${_selectedThread.threadId}/gallery?name=${Uri.encodeComponent(_selectedThread.maypoleName!)}',
                        );
                      },
                      tooltip: 'View gallery',
                    ),
                  ],
                ),
              ),
            // Chat content
            Expanded(child: chatContent),
          ],
        );
      }

      return chatContent;
    } else if (!_selectedThread.isMaypoleThread &&
        _selectedThread.dmThread != null) {
      return DmContent(
        thread: _selectedThread.dmThread!,
        showAppBar: false,
        autoFocus: true,
      );
    }

    return null;
  }

  Future<void> _shareMaypoleConversation(BuildContext context) async {
    final threadId = _selectedThread.threadId;
    final maypoleName = _selectedThread.maypoleName;
    final address = _selectedThread.address;

    if (threadId == null || maypoleName == null) return;

    try {
      final shareUrl = '${AppConfig.appUrl}/chat/$threadId';
      final locationInfo = address != null ? ' at $address' : '';
      final shareText =
          'Check out the conversation at $maypoleName$locationInfo!\n\n$shareUrl';

      if (kIsWeb) {
        // On web, copy to clipboard and show a toast
        await Clipboard.setData(ClipboardData(text: shareText));
        if (context.mounted) {
          AppToast.showSuccess(context, 'Link copied to clipboard');
        }
      } else {
        // On mobile, use the share dialog
        await Share.share(
          shareText,
          subject: 'Join the conversation on Maypole',
        );
      }
    } catch (e) {
      debugPrint('Error sharing conversation: $e');
      if (context.mounted) {
        AppToast.showError(context, 'Failed to share conversation');
      }
    }
  }

  Future<void> _handleAddPressed(BuildContext context) async {
    final result = await _openSearchOverlay();

    if (result != null && mounted) {
      final isWideScreen = MediaQuery.of(context).size.width >= 600;

      if (isWideScreen) {
        // On wide screen, automatically add to user's maypole list permanently
        final authState = ref.read(authStateProvider);
        final user = authState.value;

        if (user != null) {
          final isAlreadyInList = user.maypoleChatThreads
              .any((thread) => thread.id == result.placeId);

          if (!isAlreadyInList) {
            // Add maypole to user's list immediately
            try {
              await ref.read(maypoleChatThreadServiceProvider).addMaypoleToUserList(
                userId: user.firebaseID,
                placeId: result.placeId,
                placeName: result.placeName,
                address: result.address,
                latitude: result.latitude,
                longitude: result.longitude,
                placeType: result.placeType,
              );
            } catch (e) {
              debugPrint('⚠️ Error adding maypole to user list: $e');
              // Continue anyway - will be added when they send a message
            }
          }
        }

        // Update the selected thread to show in the content panel
        setState(() {
          _selectedThread = _SelectedThreadState(
            threadId: result.placeId,
            maypoleName: result.placeName,
            address: result.address,
            latitude: result.latitude,
            longitude: result.longitude,
            isMaypoleThread: true,
          );
        });
      } else {
        // On mobile, navigate to the chat screen
        if (context.mounted) {
          debugPrint('📱 Navigating to chat with placeType: ${result.placeType}');
          context.push('/chat/${result.placeId}', extra: {
            'name': result.placeName,
            'address': result.address,
            'latitude': result.latitude,
            'longitude': result.longitude,
            'placeType': result.placeType,
          });
        }
      }
    }
  }

  Future<PlacePrediction?> _openSearchOverlay() {
    _searchOverlayDisposeTimer?.cancel();

    final existing = _searchOverlayCompleter;
    if (existing != null && !existing.isCompleted) {
      setState(() {
        _shouldKeepSearchScreenMounted = true;
        _isSearchOverlayVisible = true;
      });
      return existing.future;
    }

    final completer = Completer<PlacePrediction?>();
    _searchOverlayCompleter = completer;

    setState(() {
      _shouldKeepSearchScreenMounted = true;
      _isSearchOverlayVisible = true;
    });

    _registerSearchOverlayHistoryEntry();
    return completer.future;
  }

  void _onSearchPlaceSelected(PlacePrediction prediction) {
    final completer = _searchOverlayCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(prediction);
    }
    _closeSearchOverlay();
  }

  void _closeSearchOverlay() {
    final completer = _searchOverlayCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(null);
    }
    _searchOverlayCompleter = null;

    _removeSearchOverlayHistoryEntry();

    setState(() {
      _isSearchOverlayVisible = false;
      _shouldKeepSearchScreenMounted = true;
    });

    _searchOverlayDisposeTimer?.cancel();
    _searchOverlayDisposeTimer = Timer(_searchScreenKeepAliveTtl, () {
      if (!mounted || _isSearchOverlayVisible) {
        return;
      }
      setState(() {
        _shouldKeepSearchScreenMounted = false;
      });
    });
  }

  void _registerSearchOverlayHistoryEntry() {
    if (!mounted || _searchOverlayHistoryEntry != null) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route == null) {
      return;
    }

    _searchOverlayHistoryEntry = LocalHistoryEntry(
      onRemove: () {
        _searchOverlayHistoryEntry = null;
        if (_isRemovingSearchOverlayHistoryEntry) {
          _isRemovingSearchOverlayHistoryEntry = false;
          return;
        }
        if (_isSearchOverlayVisible) {
          _closeSearchOverlay();
        }
      },
    );

    route.addLocalHistoryEntry(_searchOverlayHistoryEntry!);
  }

  void _removeSearchOverlayHistoryEntry() {
    final entry = _searchOverlayHistoryEntry;
    if (entry == null) {
      return;
    }

    _isRemovingSearchOverlayHistoryEntry = true;
    entry.remove();
    _searchOverlayHistoryEntry = null;
  }

  void _handleMaypoleThreadSelected(
    BuildContext context,
    String threadId,
    String maypoleName,
    String address,
    double? latitude,
    double? longitude,
    bool isWideScreen,
  ) async {
    // Increment counter and show interstitial ad based on Remote Config frequency
    _threadSwitchCount++;
    final frequency = AdConfig.interstitialFrequency;
    if (_threadSwitchCount % frequency == 0 && AdConfig.interstitialAdsEnabled) {
      final adManager = ref.read(interstitialAdManagerProvider);
      if (adManager.isAdReady) {
        await adManager.showAd();
      }
    }

    if (isWideScreen) {
      // On wide screen, update the selected thread to show in the content panel
      setState(() {
        _selectedThread = _SelectedThreadState(
          threadId: threadId,
          maypoleName: maypoleName,
          address: address,
          latitude: latitude,
          longitude: longitude,
          isMaypoleThread: true,
        );
      });
    } else {
      // On mobile, navigate immediately
      if (context.mounted) {
        context.push('/chat/$threadId', extra: {
          'name': maypoleName,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
        });
      }
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
        // On mobile, navigate immediately
        if (context.mounted) {
          context.push('/dm/$threadId', extra: dmThread);
        }
      }
    }
  }
}
