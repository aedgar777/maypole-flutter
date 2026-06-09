import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/maypolesearch/presentation/screens/maypole_search_screen.dart';
import '../features/maypolechat/presentation/screens/maypole_chat_screen.dart';
import '../features/maypolechat/presentation/screens/maypole_chat_loader.dart';
import '../features/identity/presentation/login_screen.dart';
import '../features/identity/presentation/registration_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authService.user),
    errorBuilder: (context, state) => const HomeScreen(),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentPath = state.matchedLocation;
      final uri = state.uri;

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

      // If auth is still loading AND it's a maypole chat, allow it immediately
      if (authState.isLoading && isMaypoleChat) {
        return null;
      }

      // If auth is still loading for other routes, allow public routes
      // For protected routes, redirect to login (which will show loading state)
      if (authState.isLoading) {
        if (isPublicRoute) {
          return null;
        }
        return '/login';
      }

      final isAuthenticated = authState.value != null;

      // If user is not authenticated and trying to access a protected route
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // Don't redirect authenticated users away from login/register
      // This allows logout to work properly (user signs out, navigates to login,
      // and by the time they arrive the auth state will have updated)
      // The login screen itself will handle authenticated users appropriately

      // No redirect needed
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(returnTo: state.uri.queryParameters['returnTo']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegistrationScreen(returnTo: state.uri.queryParameters['returnTo']),
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

          if (threadId == null || threadId.isEmpty) {
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
