import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/services/fcm_service.dart';
import 'package:maypole/features/identity/auth_providers.dart';

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
      debugPrint('App launched from notification: ${initialMessage.data}');
      _handleNotificationTap(initialMessage);
    }

    // Handle notification taps when app is in background
    _fcmService.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped (background): ${message.data}');
      _handleNotificationTap(message);
    });

    // Handle foreground notifications
    _fcmService.onMessage.listen((message) {
      debugPrint('Foreground notification received: ${message.notification?.title}');
      _handleForegroundNotification(message);
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (!mounted) return;

    final type = message.data['type'];
    final threadId = message.data['threadId'];

    if (type == null || threadId == null) {
      debugPrint('Invalid notification data: ${message.data}');
      return;
    }

    // Navigate to the appropriate screen based on notification type
    if (type == 'dm') {
      // Navigate to DM thread
      context.go('/home'); // Will navigate to DM tab
      // Note: You might need to pass additional navigation state to open specific thread
      debugPrint('Navigating to DM thread: $threadId');
    } else if (type == 'tag') {
      // Navigate to maypole thread
      final maypoleName = message.data['maypoleName'] ?? 'Maypole';
      context.go('/chat/$threadId', extra: maypoleName);
      debugPrint('Navigating to maypole thread: $threadId');
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
