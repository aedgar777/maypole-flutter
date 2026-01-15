import 'package:flutter/material.dart';
import 'package:maypole/features/settings/data/services/notification_service.dart';
import 'package:maypole/features/settings/data/services/fcm_service.dart';
import 'package:maypole/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Handles requesting notification and location permissions on first app use
class FirstTimePermissionsHandler {
  final NotificationService _notificationService;
  final FcmService _fcmService;
  final LocationService _locationService;

  FirstTimePermissionsHandler(
    this._notificationService,
    this._fcmService,
    this._locationService,
  );

  /// Request both notification and location permissions if this is the first time
  /// Shows the system permission dialogs directly
  /// 
  /// Returns a record with (notificationGranted, locationGranted)
  Future<({bool notification, bool location})> requestPermissionsIfNeeded(
    BuildContext context,
  ) async {
    bool notificationGranted = false;
    bool locationGranted = false;

    // Request notification permission
    final hasAskedNotification =
        await _notificationService.hasAskedForPermission();

    if (!hasAskedNotification) {
      debugPrint('First time - requesting notification permission...');
      notificationGranted =
          await _notificationService.requestNotificationPermission();

      // If granted, also request FCM permission and get token
      if (notificationGranted) {
        await _fcmService.requestPermission();
      }
    } else {
      debugPrint('Already asked for notification permission, skipping...');
      notificationGranted =
          await _notificationService.checkNotificationPermission();
    }

    // Request location permission
    final locationPermission = await _locationService.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      debugPrint('First time - requesting location permission...');
      final permission = await _locationService.requestPermission();
      locationGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } else {
      debugPrint('Already have location permission status: $locationPermission');
      locationGranted = locationPermission == LocationPermission.always ||
          locationPermission == LocationPermission.whileInUse;
    }

    return (notification: notificationGranted, location: locationGranted);
  }
}
