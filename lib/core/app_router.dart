import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/maypolesearch/presentation/screens/maypole_search_screen.dart';
import '../features/maypolechat/presentation/screens/maypole_chat_screen.dart';
import '../features/identity/presentation/login_screen.dart';
import '../features/identity/presentation/registration_screen.dart';
import '../features/identity/presentation/screens/user_profile_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/directmessages/presentation/screens/dm_screen.dart';
import '../features/directmessages/domain/dm_thread.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/account_settings_screen.dart';
import '../features/settings/presentation/screens/blocked_users_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      GoRoute(
          path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
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
          final maypoleName = state.extra as String? ?? 'Unknown';
          return MaypoleChatScreen(
            threadId: threadId,
            maypoleName: maypoleName,
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
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
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
}
