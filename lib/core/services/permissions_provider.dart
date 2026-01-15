import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/services/first_time_permissions_handler.dart';
import 'package:maypole/core/services/location_service.dart';
import 'package:maypole/features/settings/settings_providers.dart';

/// Provider for FirstTimePermissionsHandler
final firstTimePermissionsHandlerProvider =
    Provider<FirstTimePermissionsHandler>((ref) {
  return FirstTimePermissionsHandler(
    ref.watch(notificationServiceProvider),
    ref.watch(fcmServiceProvider),
    LocationService(),
  );
});
