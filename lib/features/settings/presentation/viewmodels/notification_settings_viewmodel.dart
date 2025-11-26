import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/settings/data/services/notification_service.dart';
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

  @override
  NotificationSettingsState build() {
    _notificationService = ref.read(notificationServiceProvider);
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
      state = state.copyWith(isLoading: true);
      await _notificationService.setTaggingNotificationsEnabled(enabled);
      await _loadPreferences();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update tagging notifications: $e',
      );
    }
  }

  /// Toggle direct message notifications
  Future<void> toggleDirectMessageNotifications(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true);
      await _notificationService.setDirectMessageNotificationsEnabled(enabled);
      await _loadPreferences();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update direct message notifications: $e',
      );
    }
  }

  /// Refresh permission status
  Future<void> refreshPermissionStatus() async {
    await _loadPreferences();
  }
}

/// Provider for notification settings view model
final notificationSettingsViewModelProvider = NotifierProvider<
    NotificationSettingsViewModel,
    NotificationSettingsState>(
  NotificationSettingsViewModel.new,
);
