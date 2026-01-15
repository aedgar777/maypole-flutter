import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/services/location_provider.dart';
import 'package:maypole/core/services/location_service.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/features/settings/presentation/viewmodels/notification_settings_viewmodel.dart';
import 'package:maypole/features/settings/presentation/widgets/location_features_dialog.dart';
import 'package:maypole/features/settings/settings_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() =>
      _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen>
    with WidgetsBindingObserver {
  LocationPermission? _locationPermission;

  @override
  void initState() {
    super.initState();
    // Add observer to detect when app comes back from settings
    WidgetsBinding.instance.addObserver(this);
    _loadLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permission status when app resumes
    if (state == AppLifecycleState.resumed) {
      ref
          .read(notificationSettingsViewModelProvider.notifier)
          .refreshPermissionStatus();
      ref
          .read(locationSettingsViewModelProvider.notifier)
          .refreshPermissionStatus();
      _loadLocationPermission();
    }
  }

  Future<void> _loadLocationPermission() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.checkPermission();
    if (mounted) {
      setState(() {
        _locationPermission = permission;
      });
    }
  }

  Future<void> _handleNotificationPermissionRequest() async {
    final notifier = ref.read(notificationSettingsViewModelProvider.notifier);
    final granted = await notifier.requestPermission();

    if (!mounted) return;

    if (granted) {
      AppToast.showSuccess(
        context,
        AppLocalizations.of(context)!.notificationPermissionGranted,
      );
    } else {
      // Show dialog explaining how to enable in settings
      _showNotificationPermissionDeniedDialog();
    }
  }

  Future<void> _handleLocationPermissionRequest() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.requestPermission();

    if (!mounted) return;

    setState(() {
      _locationPermission = permission;
    });

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Refresh the location settings viewmodel
      await ref.read(locationSettingsViewModelProvider.notifier).refreshPermissionStatus();
      
      // Show location features dialog if we haven't shown it before
      final shouldShow = await ref.read(locationSettingsViewModelProvider.notifier).shouldShowLocationDialog();
      
      if (mounted && shouldShow) {
        _showLocationFeaturesDialog();
      } else if (mounted) {
        AppToast.showSuccess(
          context,
          'Location permission granted',
        );
      }
    } else {
      _showLocationPermissionDeniedDialog();
    }
  }
  
  void _showLocationFeaturesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationFeaturesDialog(
        onEnableAll: () async {
          Navigator.pop(context);
          await ref.read(locationSettingsViewModelProvider.notifier).enableAllLocationFeatures();
          await ref.read(locationSettingsViewModelProvider.notifier).markDialogShown();
          if (mounted) {
            AppToast.showSuccess(
              context,
              'Location features enabled!',
            );
          }
        },
        onNoThanks: () async {
          Navigator.pop(context);
          await ref.read(locationSettingsViewModelProvider.notifier).markDialogShown();
          if (mounted) {
            AppToast.showSuccess(
              context,
              'Location permission granted',
            );
          }
        },
      ),
    );
  }

  void _showNotificationPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationPermissionDenied),
        content: Text(l10n.notificationPermissionDeniedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(notificationSettingsViewModelProvider.notifier)
                  .openSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  void _showNotificationPermissionRevokeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Notification Permission'),
        content: const Text(
          'To disable notifications, you need to change it in your device settings.\n\nWould you like to open Settings now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(notificationSettingsViewModelProvider.notifier)
                  .openSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Location Permission'),
        content: const Text(
          'To disable location access, you need to change it in your device settings.\n\nWould you like to open Settings now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final locationService = ref.read(locationServiceProvider);
              await locationService.openAppSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationState = ref.watch(notificationSettingsViewModelProvider);
    final preferences = notificationState.preferences;

    // Notification master switch is ON when system permission is granted AND at least one notification type is enabled
    final isNotificationSwitchOn = preferences.systemPermissionGranted &&
        (preferences.taggingNotificationsEnabled ||
            preferences.directMessageNotificationsEnabled);

    // Location switch is ON when permission is granted
    final isLocationSwitchOn = _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        leading: AppConfig.isWideScreen ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: notificationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Permissions Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Permissions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Master Notifications Switch
                SwitchListTile(
                  secondary: Icon(
                    isNotificationSwitchOn
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                  ),
                  title: Text(l10n.notifications),
                  subtitle: Text(
                    isNotificationSwitchOn
                        ? l10n.notificationPermissionGrantedDescription
                        : l10n.notificationPermissionDeniedDescription,
                  ),
                  value: isNotificationSwitchOn,
                  onChanged: (value) async {
                    if (value && !preferences.systemPermissionGranted) {
                      // Turning ON: Need to request permission first
                      await _handleNotificationPermissionRequest();
                    } else if (!value && preferences.systemPermissionGranted) {
                      // Turning OFF: Can't revoke from app, show dialog
                      _showNotificationPermissionRevokeDialog();
                    } else {
                      // Toggle all notifications (for app-level settings)
                      ref
                          .read(notificationSettingsViewModelProvider.notifier)
                          .toggleAllNotifications(value);
                    }
                  },
                ),

                // Location Permission Switch
                SwitchListTile(
                  secondary: Icon(
                    isLocationSwitchOn
                        ? Icons.location_on
                        : Icons.location_off,
                  ),
                  title: const Text('Location'),
                  subtitle: Text(
                    isLocationSwitchOn
                        ? 'Required for proximity features and location badges'
                        : 'Enable to verify proximity and show location badges',
                  ),
                  value: isLocationSwitchOn,
                  onChanged: (value) async {
                    if (value) {
                      await _handleLocationPermissionRequest();
                    } else {
                      // Can't disable from app, show dialog to go to settings
                      _showLocationPermissionDeniedDialog();
                    }
                  },
                ),

                const Divider(),

                // Location Features Section
                if (isLocationSwitchOn) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Location Features',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  // Show When at Location (combined feature)
                  Consumer(
                    builder: (context, ref, child) {
                      final locationState = ref.watch(locationSettingsViewModelProvider);
                      final locationPrefs = locationState.preferences;
                      
                      return SwitchListTile(
                        secondary: Icon(
                          Icons.pin_drop,
                          color: isLocationSwitchOn
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                        title: const Text('Show When at Location'),
                        subtitle: const Text(
                          'Display a pin icon next to your name when you send messages from within 100m of a place. Also restricts picture uploads to when you\'re at the location, ensuring authenticity.',
                        ),
                        value: locationPrefs.showWhenAtLocation,
                        onChanged: isLocationSwitchOn
                            ? (value) {
                                ref
                                    .read(locationSettingsViewModelProvider.notifier)
                                    .toggleShowWhenAtLocation(value);
                              }
                            : null,
                      );
                    },
                  ),

                  const Divider(),
                ],

                // Notification Types Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    l10n.notificationTypes,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Tagging Notifications
                SwitchListTile(
                  secondary: Icon(
                    Icons.local_offer,
                    color: isNotificationSwitchOn
                        ? null
                        : Theme.of(context).disabledColor,
                  ),
                  title: Text(l10n.taggingNotifications),
                  subtitle: Text(l10n.taggingNotificationsDescription),
                  value: preferences.taggingNotificationsEnabled,
                  onChanged: isNotificationSwitchOn
                      ? (value) {
                          ref
                              .read(notificationSettingsViewModelProvider
                                  .notifier)
                              .toggleTaggingNotifications(value);
                        }
                      : null,
                ),

                const Divider(),

                // Direct Message Notifications
                SwitchListTile(
                  secondary: Icon(
                    Icons.message,
                    color: isNotificationSwitchOn
                        ? null
                        : Theme.of(context).disabledColor,
                  ),
                  title: Text(l10n.directMessageNotifications),
                  subtitle: Text(l10n.directMessageNotificationsDescription),
                  value: preferences.directMessageNotificationsEnabled,
                  onChanged: isNotificationSwitchOn
                      ? (value) {
                          ref
                              .read(notificationSettingsViewModelProvider
                                  .notifier)
                              .toggleDirectMessageNotifications(value);
                        }
                      : null,
                ),

                // Info message when notification master switch is disabled
                if (!isNotificationSwitchOn)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                l10n.enableSystemNotificationsFirst,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
