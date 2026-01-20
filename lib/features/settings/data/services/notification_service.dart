import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maypole/features/settings/domain/notification_preferences.dart';

/// Service for managing notification permissions and preferences
class NotificationService {
  static const String _prefsKey = 'notification_preferences';
  static const String _hasAskedPermissionKey = 'has_asked_notification_permission';

  /// Check if we've already asked the user for notification permission
  Future<bool> hasAskedForPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasAskedPermissionKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if permission was asked: $e');
      return false;
    }
  }

  /// Mark that we've asked the user for notification permission
  Future<void> _markPermissionAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasAskedPermissionKey, true);
      debugPrint('Marked notification permission as asked');
    } catch (e) {
      debugPrint('Error marking permission as asked: $e');
    }
  }

  /// Request notification permission from the system
  /// 
  /// On iOS, uses Firebase Messaging to request permission (required for notifications)
  /// On Android 13+, uses permission_handler to show a system dialog.
  /// On Android 12 and below, this will return granted automatically.
  /// 
  /// [markAsAsked] - Whether to mark that we've asked for permission (default: true)
  /// 
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestNotificationPermission({bool markAsAsked = true}) async {
    try {
      debugPrint('Requesting notification permission...');

      bool granted;
      
      if (Platform.isIOS) {
        // On iOS, use Firebase Messaging to request permission
        // This is required for FCM to work properly
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        
        granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        
        debugPrint('Notification permission status (iOS FCM): ${settings.authorizationStatus}');
      } else {
        // On Android, use permission_handler
        final status = await Permission.notification.request();
        granted = status.isGranted;
        debugPrint('Notification permission status (Android): $status');
      }

      // Mark that we've asked for permission
      if (markAsAsked) {
        await _markPermissionAsked();
      }

      // Update stored permission status
      await _updateSystemPermissionStatus(granted);

      return granted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request notification permission on first app use (after login/registration)
  /// This will only request if we haven't asked before
  /// 
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestPermissionOnFirstUse() async {
    final hasAsked = await hasAskedForPermission();

    if (hasAsked) {
      debugPrint('Already asked for notification permission, skipping...');
      // Just check current status
      return await checkNotificationPermission();
    }

    debugPrint('First time requesting notification permission...');
    return await requestNotificationPermission();
  }

  /// Check the current notification permission status
  /// 
  /// On iOS, uses Firebase Messaging to check permission (more reliable)
  /// On Android, uses permission_handler
  /// 
  /// Returns true if permission is granted, false otherwise.
  Future<bool> checkNotificationPermission() async {
    try {
      // On iOS, use Firebase Messaging for more accurate permission checking
      // because permission_handler can be unreliable for notifications on iOS
      if (Platform.isIOS) {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.getNotificationSettings();
        final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        debugPrint('Notification permission status check (iOS FCM): ${settings.authorizationStatus} (granted: $isGranted)');
        return isGranted;
      } else {
        // On Android, use permission_handler
        final status = await Permission.notification.status;
        final isGranted = status.isGranted;
        debugPrint('Notification permission status check (Android): $status (granted: $isGranted)');
        return isGranted;
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  /// Open app settings so user can manually enable notifications
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Load notification preferences from local storage
  Future<NotificationPreferences> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      // Always check current system permission status first
      final systemPermission = await checkNotificationPermission();
      debugPrint('Loading notification preferences - system permission: $systemPermission');

      if (jsonString == null) {
        // Return defaults with current system permission
        debugPrint('No saved preferences found, using defaults with system permission: $systemPermission');
        final newPrefs = NotificationPreferences(
          systemPermissionGranted: systemPermission,
        );
        // Save the preferences so they're persisted
        await savePreferences(newPrefs);
        return newPrefs;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final preferences = NotificationPreferences.fromJson(json);
      
      debugPrint('Loaded saved preferences: tagging=${preferences.taggingNotificationsEnabled}, '
          'dm=${preferences.directMessageNotificationsEnabled}, '
          'systemPermission=${preferences.systemPermissionGranted}');

      // Update with current system permission if different
      if (preferences.systemPermissionGranted != systemPermission) {
        debugPrint('System permission changed from ${preferences.systemPermissionGranted} to $systemPermission, updating...');
        final updatedPrefs = preferences.copyWith(
          systemPermissionGranted: systemPermission,
        );
        // Save the updated permission status
        await savePreferences(updatedPrefs);
        return updatedPrefs;
      }

      return preferences;
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      final systemPermission = await checkNotificationPermission();
      return NotificationPreferences(
        systemPermissionGranted: systemPermission,
      );
    }
  }

  /// Save notification preferences to local storage
  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(preferences.toJson());
      await prefs.setString(_prefsKey, jsonString);
      debugPrint('Notification preferences saved');
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
      rethrow;
    }
  }

  /// Update tagging notification preference
  Future<void> setTaggingNotificationsEnabled(bool enabled) async {
    final preferences = await loadPreferences();
    final updated = preferences.copyWith(
      taggingNotificationsEnabled: enabled,
    );
    await savePreferences(updated);
  }

  /// Update direct message notification preference
  Future<void> setDirectMessageNotificationsEnabled(bool enabled) async {
    final preferences = await loadPreferences();
    final updated = preferences.copyWith(
      directMessageNotificationsEnabled: enabled,
    );
    await savePreferences(updated);
  }

  /// Update system permission status in stored preferences
  Future<void> _updateSystemPermissionStatus(bool granted) async {
    try {
      debugPrint('Updating system permission status to: $granted');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      NotificationPreferences preferences;
      if (jsonString == null) {
        debugPrint('No existing preferences, creating new with system permission: $granted');
        preferences = NotificationPreferences(
          systemPermissionGranted: granted,
        );
      } else {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        preferences = NotificationPreferences.fromJson(json);

        debugPrint('Current stored system permission: ${preferences.systemPermissionGranted}');
        
        // Only update if changed
        if (preferences.systemPermissionGranted == granted) {
          debugPrint('System permission unchanged, skipping save');
          return;
        }

        debugPrint('System permission changed, updating...');
        preferences = preferences.copyWith(
          systemPermissionGranted: granted,
        );
      }

      await savePreferences(preferences);
      debugPrint('System permission status saved successfully');
    } catch (e) {
      debugPrint('Error updating system permission status: $e');
    }
  }

  /// Check if notifications are effectively enabled
  /// (both system permission granted AND at least one notification type enabled)
  Future<bool> areNotificationsEnabled() async {
    final preferences = await loadPreferences();
    return preferences.systemPermissionGranted &&
        (preferences.taggingNotificationsEnabled ||
            preferences.directMessageNotificationsEnabled);
  }

  /// Toggle all notifications on/off (master switch)
  /// When turning off, disables all notification types
  /// When turning on, requests system permission if needed
  Future<bool> toggleAllNotifications(bool enabled) async {
    if (enabled) {
      // Request system permission if needed
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        final granted = await requestNotificationPermission();
        if (!granted) {
          return false;
        }
      }

      // Enable all notification types
      final preferences = await loadPreferences();
      final updated = preferences.copyWith(
        taggingNotificationsEnabled: true,
        directMessageNotificationsEnabled: true,
        systemPermissionGranted: true,
      );
      await savePreferences(updated);
      return true;
    } else {
      // Disable all notification types
      final preferences = await loadPreferences();
      final updated = preferences.copyWith(
        taggingNotificationsEnabled: false,
        directMessageNotificationsEnabled: false,
      );
      await savePreferences(updated);
      return true;
    }
  }
}
