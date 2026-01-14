import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/settings/data/services/storage_service.dart';
import 'package:maypole/features/settings/data/services/notification_service.dart';
import 'package:maypole/features/settings/data/services/first_time_notification_handler.dart';
import 'package:maypole/features/settings/data/services/fcm_service.dart';
import 'package:maypole/features/settings/domain/settings_state.dart';
import 'package:maypole/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:maypole/features/settings/presentation/viewmodels/location_settings_viewmodel.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

final firstTimeNotificationHandlerProvider = Provider<
    FirstTimeNotificationHandler>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final fcmService = ref.watch(fcmServiceProvider);
  return FirstTimeNotificationHandler(notificationService, fcmService);
});

final settingsViewModelProvider = NotifierProvider<
    SettingsViewModel,
    SettingsState>(
  SettingsViewModel.new,
);

final locationSettingsViewModelProvider = NotifierProvider<
    LocationSettingsViewModel,
    LocationSettingsState>(
  LocationSettingsViewModel.new,
);
