import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:permission_handler/permission_handler.dart';
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
  /// On Android 13+, this will show a system dialog.
  /// On iOS, this will show a system dialog on first request.
  /// On Android 12 and below, this will return granted automatically.
  /// 
  /// [markAsAsked] - Whether to mark that we've asked for permission (default: true)
  /// 
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestNotificationPermission({bool markAsAsked = true}) async {
    try {
      debugPrint('Requesting notification permission...');

      final status = await Permission.notification.request();

      debugPrint('Notification permission status: $status');

      final granted = status.isGranted;

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
  /// Returns true if permission is granted, false otherwise.
  Future<bool> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
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

      if (jsonString == null) {
        // Return defaults and check system permission
        final systemPermission = await checkNotificationPermission();
        return NotificationPreferences(
          systemPermissionGranted: systemPermission,
        );
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final preferences = NotificationPreferences.fromJson(json);

      // Always check current system permission status
      final systemPermission = await checkNotificationPermission();

      return preferences.copyWith(
        systemPermissionGranted: systemPermission,
      );
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
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      NotificationPreferences preferences;
      if (jsonString == null) {
        preferences = NotificationPreferences(
          systemPermissionGranted: granted,
        );
      } else {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        preferences = NotificationPreferences.fromJson(json);

        // Only update if changed
        if (preferences.systemPermissionGranted == granted) {
          return;
        }

        preferences = preferences.copyWith(
          systemPermissionGranted: granted,
        );
      }

      await savePreferences(preferences);
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
}
