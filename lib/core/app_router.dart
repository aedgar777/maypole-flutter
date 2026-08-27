import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/maypolesearch/presentation/screens/maypole_search_screen.dart';
import '../features/maypolechat/presentation/screens/maypole_chat_screen.dart';
import '../features/maypolechat/presentation/screens/maypole_chat_loader.dart';
import '../features/identity/presentation/login_screen.dart';
import '../features/identity/presentation/registration_screen.dart';
import '../features/identity/presentation/google_username_screen.dart';
import '../features/identity/presentation/email_verified_screen.dart';
import '../features/identity/presentation/screens/user_profile_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/directmessages/presentation/screens/dm_screen.dart';
import '../features/directmessages/domain/dm_thread.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/child_safety_standards_screen.dart';
import '../features/settings/presentation/screens/preferences_screen.dart';
import '../features/settings/presentation/screens/account_settings_screen.dart';
import '../features/settings/presentation/screens/blocked_users_screen.dart';
import '../features/settings/presentation/screens/help_screen.dart';
import '../features/identity/auth_providers.dart';
import '../features/maypolechat/presentation/screens/maypole_gallery_screen.dart';

bool _isPublicMaypoleChatRoute({
  required Uri uri,
  required String matchedLocation,
  required String? fullPath,
}) {
  // Legacy Maypole chat links are public. Gallery links are also read-only safe.
  if (uri.path.startsWith('/chat/') ||
      matchedLocation.startsWith('/chat/') ||
      fullPath?.startsWith('/chat/') == true) {
    return true;
  }

  // Current share links are semantic URLs shaped like:
  // /:locationSlug/:placeSlug?id=:googlePlaceId
  final threadId = uri.queryParameters['id'];
  final hasThreadId = threadId != null && threadId.trim().isNotEmpty;
  if (!hasThreadId || uri.pathSegments.length != 2) {
    return false;
  }

  final reservedTopLevelRoutes = <String>{
    'dm',
    'home',
    'login',
    'register',
    'search',
    'settings',
    'user-profile',
  };

  return !reservedTopLevelRoutes.contains(uri.pathSegments.first);
}

/// Firebase auth-action links (password reset, email verification, etc.)
/// are served by the static `auth-action.html` page on our web hosting.
/// When such a link is opened on mobile via App Links / Universal Links, the
/// path is captured by the Flutter app instead of the browser. Since the
/// Flutter app can't process these action codes (that's the web page's job),
/// we forward the user out to their default browser so the reset flow can
/// complete there.
bool _isAuthActionPath(String path) {
  return path == '/auth-action' || path == '/auth-action.html';
}

/// Guards against launching the external browser multiple times if
/// `redirect` fires repeatedly for the same incoming link.
String? _lastLaunchedAuthActionUrl;

void _forwardAuthActionToBrowser(Uri uri) {
  final target = uri.toString();
  if (_lastLaunchedAuthActionUrl == target) {
    return;
  }
  _lastLaunchedAuthActionUrl = target;
  // Fire-and-forget: `redirect` must remain synchronous.
  unawaited(
    // `inAppBrowserView` opens a Chrome Custom Tab / SFSafariViewController,
    // which — unlike `externalApplication` — does not re-trigger our Android
    // App Link / iOS Universal Link intent filter, so we won't bounce the
    // user right back into the app.
    launchUrl(uri, mode: LaunchMode.inAppBrowserView).catchError((error) {
      debugPrint('🧭 [DeepLink] failed to forward auth-action to browser: $error');
      return false;
    }),
  );
}

/// Dismisses the in-app browser we opened for an auth-action link.
///
/// `auth-action.html` hands back to the native app with a `maypole://` URL.
/// iOS delivers that to the app *underneath* the SFSafariViewController we
/// presented — the browser sheet is not dismissed automatically, so without
/// this the user keeps staring at the web page even though the app already
/// routed correctly. Worse, the page's own "app didn't open" fallback then
/// fires and navigates that still-visible sheet to the mobile web app, which
/// looks exactly like the deep link having failed.
///
/// Closing the sheet also lets the page observe `pagehide`/`visibilitychange`,
/// which cancels that fallback at the source.
void _dismissAuthActionBrowser() {
  _lastLaunchedAuthActionUrl = null;
  // Fire-and-forget: `redirect` must remain synchronous.
  unawaited(
    closeInAppWebView().catchError((error) {
      debugPrint('🧭 [DeepLink] failed to close in-app browser: $error');
    }),
  );
}

/// Whether [uri] is somewhere worth returning to after finishing sign-up.
///
/// The auth screens themselves are not: bouncing a newly-created user back to
/// `/login` would undo the sign-up they just completed.
bool _isRoutableReturnTarget(Uri uri) {
  final target = uri.toString();
  return target.isNotEmpty &&
      target != '/' &&
      !target.startsWith('/login') &&
      !target.startsWith('/register') &&
      !target.startsWith('/complete-profile');
}

/// Builds the login redirect target, preserving the originally requested
/// location (path + query) as a `returnTo` parameter.
///
/// This ensures that when an unauthenticated user opens a deep link to a
/// protected route, they are sent to the matching screen after authenticating
/// instead of being dropped on the home screen. [LoginScreen] consumes the
/// `returnTo` value to navigate post-auth.
String _loginRedirect(Uri uri) {
  final target = uri.toString();

  // Never round-trip back to the auth screens.
  if (target.isEmpty ||
      target == '/' ||
      target.startsWith('/login') ||
      target.startsWith('/register')) {
    return '/login';
  }

  return Uri(
    path: '/login',
    queryParameters: {'returnTo': target},
  ).toString();
}

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authService.user),
    errorBuilder: (context, state) {
      debugPrint(
        '🧭 [DeepLink] errorBuilder hit -> uri="${state.uri}" '
        'matchedLocation="${state.matchedLocation}" fullPath="${state.fullPath}" '
        'error=${state.error}',
      );
      return const HomeScreen();
    },
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentPath = state.matchedLocation;
      final uri = state.uri;

      debugPrint(
        '🧭 [DeepLink] redirect ENTER uri="$uri" matchedLocation="$currentPath" '
        'fullPath="${state.fullPath}" pathSegments=${uri.pathSegments} '
        'query=${uri.queryParameters} authLoading=${authState.isLoading} '
        'authed=${authState.value != null}',
      );

      // Firebase auth-action links (password reset, email verification) are
      // handled exclusively by the static web page. On mobile the App Link
      // intercepts the URL and lands here — bounce it out to the browser so
      // the user can complete the flow instead of getting stranded on login.
      if (!kIsWeb && _isAuthActionPath(uri.path)) {
        debugPrint(
          '🧭 [DeepLink] redirect DECISION: forward auth-action to browser '
          '(uri="$uri")',
        );
        _forwardAuthActionToBrowser(uri);
        return '/login';
      }

      // The `maypole://` scheme is only ever used by auth-action.html handing
      // control back to us, so its arrival means the in-app browser is still
      // presented on top of the app. Dismiss it before routing onward.
      if (!kIsWeb && uri.scheme == 'maypole') {
        debugPrint(
          '🧭 [DeepLink] redirect: app-scheme handoff received, '
          'dismissing in-app browser (uri="$uri")',
        );
        _dismissAuthActionBrowser();
      }

      // A completed password reset hands back to `/login?passwordReset=success`,
      // but the user is usually already sitting on `/login` — that is where
      // they tapped "Forgot password?". go_router has already folded the query
      // into its configuration by the time this redirect runs, so it considers
      // itself up to date, skips the rebuild, and LoginScreen never sees the
      // parameter. (Returning the location as a redirect does not help: it is
      // the location the router is already on.) Carry the result out of band
      // instead. Scheme-agnostic so it also covers the https fallback the page
      // uses when the custom-scheme handoff doesn't take.
      if (!kIsWeb && uri.queryParameters['passwordReset'] == 'success') {
        // `redirect` must stay synchronous and must not mutate providers
        // mid-build, so defer the write.
        Future.microtask(
          () => ref.read(passwordResetSignalProvider.notifier).signal(),
        );
      }

      // A Google sign-up that has authenticated but not yet chosen a username
      // is in a state the auth stream cannot express: Firebase has a user, but
      // [authStateProvider] emits null because no profile document exists. The
      // checks below would read that as "signed out" and send them to login,
      // abandoning the account they just created. Hold them on the username
      // screen until they either finish or explicitly cancel.
      // Two sources, because the two can disagree after a relaunch: the
      // provider holds the flow started in this session, while the service
      // recognises one left unfinished in a previous one. Either means the
      // user still owes us a username.
      final pendingGoogleProfile = ref.read(googleProfileSetupProvider);
      final hasPendingGoogleProfile =
          pendingGoogleProfile != null || authService.isGoogleProfileSetupPending;

      if (hasPendingGoogleProfile) {
        // Restore the details the username screen shows (the Google address,
        // the suggested name) when this is a resumed flow. `redirect` must stay
        // synchronous and must not write to providers mid-build, so defer it.
        if (pendingGoogleProfile == null) {
          final resumed = authService.resumePendingGoogleProfile();
          if (resumed != null) {
            Future.microtask(
              () => ref.read(googleProfileSetupProvider.notifier).start(resumed),
            );
          }
        }

        if (currentPath == '/complete-profile') {
          debugPrint('🧭 [DeepLink] redirect DECISION: allow (completing profile)');
          return null;
        }
        // Preserve the deep link they were originally headed for, so finishing
        // sign-up still lands them where they meant to go.
        final returnTo = uri.queryParameters['returnTo'] ??
            (_isRoutableReturnTarget(uri) ? uri.toString() : null);
        final target = Uri(
          path: '/complete-profile',
          queryParameters: returnTo == null ? null : {'returnTo': returnTo},
        ).toString();
        debugPrint('🧭 [DeepLink] redirect DECISION: -> "$target" (profile incomplete)');
        return target;
      }

      // Define public routes that don't require authentication
      final publicRoutes = [
        '/login',
        '/register',
        '/privacy-policy',
        '/child-safety-standards',
        '/help',
        '/email-verified',
      ];

      final isMaypoleChat = _isPublicMaypoleChatRoute(
        uri: uri,
        matchedLocation: currentPath,
        fullPath: state.fullPath,
      );

      final isPublicRoute = publicRoutes.contains(currentPath) || isMaypoleChat;

      debugPrint(
        '🧭 [DeepLink] redirect classify isMaypoleChat=$isMaypoleChat '
        'isPublicRoute=$isPublicRoute',
      );

      // If auth is still loading AND it's a maypole chat, allow it immediately
      if (authState.isLoading && isMaypoleChat) {
        debugPrint('🧭 [DeepLink] redirect DECISION: allow (loading+chat)');
        return null;
      }

      // If auth is still loading for other routes, allow public routes
      // For protected routes, redirect to login (which will show loading state)
      if (authState.isLoading) {
        if (isPublicRoute) {
          debugPrint('🧭 [DeepLink] redirect DECISION: allow (loading+public)');
          return null;
        }
        final target = _loginRedirect(uri);
        debugPrint('🧭 [DeepLink] redirect DECISION: -> "$target" (loading+protected)');
        return target;
      }

      final isAuthenticated = authState.value != null;

      // If user is not authenticated and trying to access a protected route,
      // redirect to login while preserving the deep-link destination so the
      // user lands on the requested screen after signing in.
      if (!isAuthenticated && !isPublicRoute) {
        final target = _loginRedirect(uri);
        debugPrint('🧭 [DeepLink] redirect DECISION: -> "$target" (unauth+protected)');
        return target;
      }

      // Don't redirect authenticated users away from login/register
      // This allows logout to work properly (user signs out, navigates to login,
      // and by the time they arrive the auth state will have updated)
      // The login screen itself will handle authenticated users appropriately

      // No redirect needed
      debugPrint('🧭 [DeepLink] redirect DECISION: allow (no redirect)');
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          returnTo: state.uri.queryParameters['returnTo'],
          passwordResetSuccess:
              state.uri.queryParameters['passwordReset'] == 'success',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegistrationScreen(returnTo: state.uri.queryParameters['returnTo']),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => GoogleUsernameScreen(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      GoRoute(
        path: '/email-verified',
        builder: (context, state) => EmailVerifiedScreen(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          return MaterialPage(
            key: state.pageKey,
            allowSnapshotting: false,
            child: HomeScreen(
              initialTab: extra?['initialTab'] as int?,
              selectedDmThreadId: extra?['selectedDmThreadId'] as String?,
              selectedDmThread: extra?['selectedDmThread'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: MaypoleSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (context, state) {
          final threadId = state.pathParameters['threadId']!;
          // Handle both legacy String format and new Map format
          final extra = state.extra;
          final String? maypoleName;
          final String? address;
          final double? latitude;
          final double? longitude;

          String? placeType;
          String? googlePlaceId;
          String? locationSlug;
          String? placeSlug;

          if (extra is Map<String, dynamic>) {
            maypoleName = extra['name'] as String?;
            address = extra['address'] as String?;
            latitude = extra['latitude'] as double?;
            longitude = extra['longitude'] as double?;
            placeType = extra['placeType'] as String?;
            googlePlaceId = extra['googlePlaceId'] as String?;
            locationSlug = extra['locationSlug'] as String?;
            placeSlug = extra['placeSlug'] as String?;
          } else {
            maypoleName = extra as String?;
            address = null;
            latitude = null;
            longitude = null;
            placeType = null;
          }

          // If we have complete place info, go directly to chat screen
          if (maypoleName != null &&
              maypoleName.isNotEmpty &&
              maypoleName != 'Unknown') {
            return MaypoleChatScreen(
              threadId: threadId,
              maypoleName: maypoleName,
              address: address,
              latitude: latitude,
              longitude: longitude,
              placeType: placeType,
              googlePlaceId: googlePlaceId,
              locationSlug: locationSlug,
              placeSlug: placeSlug,
            );
          }

          // Otherwise, use loader to fetch place details from Firestore or Google Places API
          return MaypoleChatLoader(threadId: threadId);
        },
      ),
      GoRoute(
        path: '/dm/:threadId',
        builder: (context, state) {
          final thread = state.extra as DMThread;
          return DmScreen(thread: thread);
        },
      ),
      GoRoute(
        path: '/chat/:threadId/gallery',
        builder: (context, state) {
          final threadId = state.pathParameters['threadId']!;
          final maypoleName = state.uri.queryParameters['name'] ?? 'Unknown';
          final initialImageId = state.uri.queryParameters['imageId'];
          return MaypoleGalleryScreen(
            threadId: threadId,
            maypoleName: maypoleName,
            initialImageId: initialImageId,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/child-safety-standards',
        builder: (context, state) => const ChildSafetyStandardsScreen(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
      GoRoute(
        path: '/user-profile/:firebaseId',
        builder: (context, state) {
          final firebaseId = state.pathParameters['firebaseId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return UserProfileScreen(
            username: extra?['username'] as String? ?? '',
            firebaseId: firebaseId,
            profilePictureUrl: extra?['profilePictureUrl'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/:locationSlug/:placeSlug',
        builder: (context, state) {
          final threadId = state.uri.queryParameters['id'];
          final locationSlug = state.pathParameters['locationSlug'];
          final placeSlug = state.pathParameters['placeSlug'];

          debugPrint(
            '🧭 [DeepLink] semantic route builder uri="${state.uri}" '
            'locationSlug="$locationSlug" placeSlug="$placeSlug" '
            'threadId="$threadId"',
          );

          if (threadId == null || threadId.isEmpty) {
            debugPrint(
              '🧭 [DeepLink] semantic route: missing thread id -> HomeScreen',
            );
            return const HomeScreen();
          }

          return MaypoleChatLoader(
            threadId: threadId,
            locationSlug: locationSlug,
            placeSlug: placeSlug,
          );
        },
      ),
    ],
  );
});

/// Helper class to refresh the router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
