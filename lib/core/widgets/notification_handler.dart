import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/services/fcm_service.dart';
import 'package:maypole/core/utils/screen_utils.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import '../../core/app_router.dart';

/// Widget that handles Firebase Cloud Messaging notifications
/// Place this at the root of your app to handle notification taps and foreground messages
class NotificationHandler extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationHandler({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<NotificationHandler> {
  final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  Future<void> _setupNotificationHandlers() async {
    // Handle notification that launched the app (app was terminated)
    final initialMessage = await _fcmService.getInitialMessage();
    if (initialMessage != null && mounted) {
      _handleNotificationTap(initialMessage);
    }

    // Handle notification taps when app is in background
    _fcmService.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });

    // Handle foreground notifications
    _fcmService.onMessage.listen((message) {
      _handleForegroundNotification(message);
    });
  }

  void _handleNotificationTap(RemoteMessage message) async {
    
    if (!mounted) {
      return;
    }

    final type = message.data['type'];
    final threadId = message.data['threadId'];


    if (type == null || threadId == null) {
      return;
    }

    // Navigate to the appropriate screen based on notification type
    if (type == 'dm') {
      
      // Mark DM thread as read when notification is tapped
      await _markDmThreadAsRead(threadId);
      
      // Wait a moment for auth state to settle before navigating
      // This prevents the router redirect from interfering
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) {
        return;
      }
      
      // Fetch the DM thread and navigate to it
      final dmThread = await _fetchDMThread(threadId);
      
      
      if (!mounted) {
        return;
      }
      
      final isWide = ScreenUtils.isWideScreenFromContext(context);
      
      // Get the router from the provider to ensure proper navigation
      final router = ref.read(routerProvider);
      
      if (dmThread != null) {
        if (isWide) {
          router.go('/home', extra: {
            'initialTab': 1, // DM tab
            'selectedDmThreadId': threadId,
            'selectedDmThread': dmThread,
          });
        } else {
          // On mobile, navigate directly to DM screen
          router.push('/dm/$threadId', extra: dmThread);
        }
      } else {
        router.go('/home', extra: {'initialTab': 1});
      }
    } else if (type == 'tag') {
      // Wait a moment for auth state to settle before navigating
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Get the router from the provider
      final router = ref.read(routerProvider);
      
      final maypoleName = message.data['maypoleName'] ?? 'Maypole';
      router.go('/chat/$threadId', extra: maypoleName);
    }
  }

  Future<DMThread?> _fetchDMThread(String threadId) async {
    try {
      final dmThread = await ref.read(dmThreadServiceProvider).getDMThreadById(threadId);
      return dmThread;
    } catch (e) {
      return null;
    }
  }

  Future<void> _markDmThreadAsRead(String threadId) async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null) return;

    try {
      await ref.read(dmThreadServiceProvider).markThreadAsRead(
        threadId,
        currentUser.firebaseID,
      );
    } catch (e) {
    }
  }

  void _handleForegroundNotification(RemoteMessage message) {
    if (!mounted) return;

    final notification = message.notification;
    if (notification == null) return;

    // Show a snackbar for foreground notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'New notification',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null)
              Text(notification.body!),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationTap(message),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
