import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/settings/data/services/notification_service.dart';
import 'package:maypole/features/settings/data/services/fcm_service.dart';
import 'package:maypole/features/settings/domain/notification_preferences.dart';
import 'package:maypole/features/settings/settings_providers.dart';

/// State for notification settings
class NotificationSettingsState {
  final NotificationPreferences preferences;
  final bool isLoading;
  final String? error;

  const NotificationSettingsState({
    required this.preferences,
    this.isLoading = false,
    this.error,
  });

  NotificationSettingsState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    String? error,
  }) {
    return NotificationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// View model for managing notification settings
class NotificationSettingsViewModel
    extends Notifier<NotificationSettingsState> {
  late final NotificationService _notificationService;
  late final FcmService _fcmService;

  @override
  NotificationSettingsState build() {
    _notificationService = ref.read(notificationServiceProvider);
    _fcmService = ref.read(fcmServiceProvider);
    _loadPreferences();
    return NotificationSettingsState(
      preferences: const NotificationPreferences(),
      isLoading: true,
    );
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _notificationService.loadPreferences();
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load preferences: $e',
      );
    }
  }

  /// Request system notification permission
  Future<bool> requestPermission() async {
    try {
      state = state.copyWith(isLoading: true);
      final granted = await _notificationService
          .requestNotificationPermission();

      // If granted, also request FCM permission and get token
      if (granted) {
        await _fcmService.requestPermission();
      }

      // Reload preferences to update system permission status
      await _loadPreferences();

      return granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permission: $e',
      );
      return false;
    }
  }

  /// Open system settings
  Future<void> openSettings() async {
    await _notificationService.openSettings();
  }

  /// Toggle tagging notifications
  Future<void> toggleTaggingNotifications(bool enabled) async {
    try {
      // Optimistic update - update UI immediately
      final updatedPreferences = state.preferences.copyWith(
        taggingNotificationsEnabled: enabled,
      );
      state = state.copyWith(preferences: updatedPreferences);

      // Save in background
      await _notificationService.setTaggingNotificationsEnabled(enabled);
    } catch (e) {
      // Revert on error
      await _loadPreferences();
      state = state.copyWith(
        error: 'Failed to update tagging notifications: $e',
      );
    }
  }

  /// Toggle direct message notifications
  Future<void> toggleDirectMessageNotifications(bool enabled) async {
    try {
      // Optimistic update - update UI immediately
      final updatedPreferences = state.preferences.copyWith(
        directMessageNotificationsEnabled: enabled,
      );
      state = state.copyWith(preferences: updatedPreferences);

      // Save in background
      await _notificationService.setDirectMessageNotificationsEnabled(enabled);
    } catch (e) {
      // Revert on error
      await _loadPreferences();
      state = state.copyWith(
        error: 'Failed to update direct message notifications: $e',
      );
    }
  }

  /// Refresh permission status
  Future<void> refreshPermissionStatus() async {
    await _loadPreferences();
  }

  /// Toggle all notifications (master switch)
  Future<void> toggleAllNotifications(bool enabled) async {
    try {
      if (enabled) {
        // When enabling, optimistically update to enable all types
        final updatedPreferences = state.preferences.copyWith(
          taggingNotificationsEnabled: true,
          directMessageNotificationsEnabled: true,
        );
        state = state.copyWith(preferences: updatedPreferences);
      } else {
        // When disabling, optimistically update to disable all types
        final updatedPreferences = state.preferences.copyWith(
          taggingNotificationsEnabled: false,
          directMessageNotificationsEnabled: false,
        );
        state = state.copyWith(preferences: updatedPreferences);
      }

      // Save in background
      final success = await _notificationService.toggleAllNotifications(
        enabled,
      );

      if (success && enabled) {
        // If enabled, also request FCM permission
        await _fcmService.requestPermission();
      }
    } catch (e) {
      // Revert on error
      await _loadPreferences();
      state = state.copyWith(
        error: 'Failed to toggle notifications: $e',
      );
    }
  }
}

/// Provider for notification settings view model
final notificationSettingsViewModelProvider = NotifierProvider<
    NotificationSettingsViewModel,
    NotificationSettingsState>(
  NotificationSettingsViewModel.new,
);
