import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maypole/core/app_session.dart';

/// Service for managing Firebase Cloud Messaging tokens and notifications
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = AppSession();

  /// Initialize FCM WITHOUT requesting permissions
  /// Call this to set up message listeners without triggering permission prompt
  Future<void> initialize() async {
    try {
      // Check existing permission status without requesting
      final settings = await _messaging.getNotificationSettings();
      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Permission already granted, get the token
        final token = await _messaging.getToken();
        debugPrint('FCM Token: $token');

        if (token != null) {
          await _updateUserFcmToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_updateUserFcmToken);
      }

      // Set up foreground message handler (works regardless of permission status)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up background message handler (already handled in main.dart)
      // FirebaseMessaging.onBackgroundMessage is static and must be
      // defined at the top level
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Request notification permissions and initialize token if granted
  /// This should be called AFTER your custom permission UI
  Future<bool> requestPermission() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get the token
        final token = await _messaging.getToken();
        debugPrint('FCM Token: $token');

        if (token != null) {
          await _updateUserFcmToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_updateUserFcmToken);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting FCM permission: $e');
      return false;
    }
  }

  /// Update the user's FCM token in Firestore
  Future<void> _updateUserFcmToken(String token) async {
    try {
      final user = _session.currentUser;
      if (user == null) {
        debugPrint('No current user, skipping FCM token update');
        return;
      }

      await _firestore.collection('users').doc(user.firebaseID).update({
        'fcmToken': token,
      });

      debugPrint('FCM token updated for user ${user.username}');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // You can show a local notification here or update the UI
    // For now, we'll just log it
  }

  /// Delete the FCM token (e.g., on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM token deleted');

      final user = _session.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.firebaseID).update({
          'fcmToken': null,
        });
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
