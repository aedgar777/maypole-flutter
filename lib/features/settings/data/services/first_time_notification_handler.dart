import 'package:flutter/material.dart';
import 'package:maypole/features/settings/data/services/notification_service.dart';
import 'package:maypole/features/settings/data/services/fcm_service.dart';

/// Handles requesting notification permissions on first app use (after login/registration)
class FirstTimeNotificationHandler {
  final NotificationService _notificationService;
  final FcmService _fcmService;

  FirstTimeNotificationHandler(this._notificationService, this._fcmService);

  /// Request notification permission if this is the first time
  /// Shows the system permission dialog directly
  /// 
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestPermissionIfNeeded(BuildContext context) async {
    final hasAsked = await _notificationService.hasAskedForPermission();

    if (hasAsked) {
      debugPrint('Already asked for notification permission, skipping...');
      return await _notificationService.checkNotificationPermission();
    }

    debugPrint('First time - requesting notification permission...');

    // Request the system permission directly (no custom dialog)
    final granted = await _notificationService.requestNotificationPermission();

    // If granted, also request FCM permission and get token
    if (granted) {
      await _fcmService.requestPermission();
    }

    return granted;
  }

}
