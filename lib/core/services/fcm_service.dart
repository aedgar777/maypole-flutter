import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service for managing Firebase Cloud Messaging (FCM) tokens and push notifications
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request notification permissions
  /// Returns the FCM token if successful, null otherwise
  Future<String?> initialize() async {
    try {
      // Request permission for iOS
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );


      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _messaging.getToken();
        return token;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save FCM token to user's Firestore document
  /// This allows the backend to send notifications to this device
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove FCM token from user's Firestore document
  /// Call this when user logs out or revokes notification permission
  Future<void> removeFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Listen for token refresh events
  /// FCM tokens can be refreshed by the system, so we need to update Firestore
  Stream<String> onTokenRefresh() {
    return _messaging.onTokenRefresh;
  }

  /// Setup FCM for a user
  /// Call this after user logs in
  Future<void> setupForUser(String userId) async {
    try {
      final token = await initialize();
      if (token != null) {
        await saveFCMToken(userId, token);

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          saveFCMToken(userId, newToken);
        });
      }
    } catch (e) {
    }
  }

  /// Cleanup FCM for a user
  /// Call this when user logs out
  Future<void> cleanupForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await removeFCMToken(userId, token);
      }
    } catch (e) {
    }
  }

  /// Handle foreground messages
  /// Returns a stream of messages received while app is in foreground
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Handle background messages when user taps notification
  /// Returns a stream of messages that opened the app from background/terminated state
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Get the message that opened the app (if any)
  /// Call this on app startup to handle notification that launched the app
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  /// Mark a DM thread as read from a notification action
  /// This can be called when the user taps a "Mark as Read" button in the notification
  /// Note: On iOS, notification actions require additional setup in the native code
  /// On Android, this works with notification reply actions
  Future<void> markDmThreadAsReadFromNotification(String threadId, String userId) async {
    try {
      await _firestore.collection('DMThreads').doc(threadId).update({
        'unreadBy.$userId': false,
      });
    } catch (e) {
    }
  }
}
