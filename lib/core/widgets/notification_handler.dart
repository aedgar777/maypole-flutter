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

  void _handleNotificationTap(RemoteMessage message) async {
    debugPrint('🔔 NOTIFICATION: _handleNotificationTap called');
    debugPrint('🔔 NOTIFICATION: message.data=${message.data}');
    
    if (!mounted) {
      debugPrint('🔔 NOTIFICATION: Widget not mounted, returning');
      return;
    }

    final type = message.data['type'];
    final threadId = message.data['threadId'];

    debugPrint('🔔 NOTIFICATION: type=$type, threadId=$threadId');

    if (type == null || threadId == null) {
      debugPrint('🔔 NOTIFICATION: Invalid notification data');
      return;
    }

    // Navigate to the appropriate screen based on notification type
    if (type == 'dm') {
      debugPrint('🔔 NOTIFICATION: Handling DM notification');
      
      // Mark DM thread as read when notification is tapped
      await _markDmThreadAsRead(threadId);
      
      // Wait a moment for auth state to settle before navigating
      // This prevents the router redirect from interfering
      debugPrint('🔔 NOTIFICATION: Waiting 300ms for auth to settle');
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) {
        debugPrint('🔔 NOTIFICATION: Widget not mounted after delay, returning');
        return;
      }
      
      // Fetch the DM thread and navigate to it
      debugPrint('🔔 NOTIFICATION: Fetching DM thread $threadId');
      final dmThread = await _fetchDMThread(threadId);
      
      debugPrint('🔔 NOTIFICATION: dmThread=${dmThread != null ? 'FOUND' : 'NULL'}');
      
      if (!mounted) {
        debugPrint('🔔 NOTIFICATION: Widget not mounted after fetch, returning');
        return;
      }
      
      final isWide = ScreenUtils.isWideScreenFromContext(context);
      debugPrint('🔔 NOTIFICATION: isWideScreen=$isWide');
      
      // Get the router from the provider to ensure proper navigation
      final router = ref.read(routerProvider);
      
      if (dmThread != null) {
        if (isWide) {
          debugPrint('🔔 NOTIFICATION: Navigating to /home with DM tab (web)');
          router.go('/home', extra: {
            'initialTab': 1, // DM tab
            'selectedDmThreadId': threadId,
            'selectedDmThread': dmThread,
          });
        } else {
          debugPrint('🔔 NOTIFICATION: Navigating to /dm/$threadId (mobile)');
          // On mobile, navigate directly to DM screen
          router.push('/dm/$threadId', extra: dmThread);
        }
      } else {
        debugPrint('🔔 NOTIFICATION: dmThread is null, falling back to /home');
        router.go('/home', extra: {'initialTab': 1});
      }
      debugPrint('🔔 NOTIFICATION: Navigation complete');
    } else if (type == 'tag') {
      debugPrint('🔔 NOTIFICATION: Handling tag notification');
      // Wait a moment for auth state to settle before navigating
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Get the router from the provider
      final router = ref.read(routerProvider);
      
      final maypoleName = message.data['maypoleName'] ?? 'Maypole';
      debugPrint('🔔 NOTIFICATION: Navigating to /chat/$threadId');
      router.go('/chat/$threadId', extra: maypoleName);
    }
  }

  Future<DMThread?> _fetchDMThread(String threadId) async {
    try {
      final dmThread = await ref.read(dmThreadServiceProvider).getDMThreadById(threadId);
      return dmThread;
    } catch (e) {
      debugPrint('❌ Error fetching DM thread from notification: $e');
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
      debugPrint('✓ Marked DM thread as read from notification: $threadId');
    } catch (e) {
      debugPrint('❌ Error marking DM thread as read: $e');
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
