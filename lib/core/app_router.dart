import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/maypolesearch/presentation/screens/maypole_search_screen.dart';
import '../features/maypolechat/presentation/screens/maypole_chat_screen.dart';
import '../features/identity/presentation/login_screen.dart';
import '../features/identity/presentation/registration_screen.dart';
import '../features/identity/presentation/email_verified_screen.dart';
import '../features/identity/presentation/screens/user_profile_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/directmessages/presentation/screens/dm_screen.dart';
import '../features/directmessages/domain/dm_thread.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/preferences_screen.dart';
import '../features/settings/presentation/screens/account_settings_screen.dart';
import '../features/settings/presentation/screens/blocked_users_screen.dart';
import '../features/identity/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authService.user),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.value != null;
      final currentPath = state.matchedLocation;
      
      // Define public routes that don't require authentication
      final publicRoutes = ['/login', '/register', '/privacy-policy', '/email-verified'];
      final isPublicRoute = publicRoutes.contains(currentPath);
      
      // If user is not authenticated and trying to access a protected route
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }
      
      // If user is authenticated and on login screen, redirect to home
      if (isAuthenticated && currentPath == '/login') {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
          path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/email-verified',
        builder: (context, state) => const EmailVerifiedScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
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
          final String maypoleName;
          final String? address;
          final double? latitude;
          final double? longitude;

          if (extra is Map<String, dynamic>) {
            maypoleName = extra['name'] as String? ?? 'Unknown';
            address = extra['address'] as String?;
            latitude = extra['latitude'] as double?;
            longitude = extra['longitude'] as double?;
          } else {
            maypoleName = extra as String? ?? 'Unknown';
            address = null;
            latitude = null;
            longitude = null;
          }

          return MaypoleChatScreen(
            threadId: threadId,
            maypoleName: maypoleName,
            address: address,
            latitude: latitude,
            longitude: longitude,
          );
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
