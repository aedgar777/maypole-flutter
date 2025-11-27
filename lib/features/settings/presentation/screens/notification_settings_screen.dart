import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/features/settings/presentation/viewmodels/notification_settings_viewmodel.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Add observer to detect when app comes back from settings
    WidgetsBinding.instance.addObserver(this);
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
    }
  }

  Future<void> _handlePermissionRequest() async {
    final notifier = ref.read(notificationSettingsViewModelProvider.notifier);
    final granted = await notifier.requestPermission();

    if (!mounted) return;

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.notificationPermissionGranted),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show dialog explaining how to enable in settings
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationSettingsViewModelProvider);
    final preferences = state.preferences;

    // Master switch is ON when system permission is granted AND at least one notification type is enabled
    final isMasterSwitchOn = preferences.systemPermissionGranted &&
        (preferences.taggingNotificationsEnabled ||
            preferences.directMessageNotificationsEnabled);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // Master Notifications Switch
          SwitchListTile(
            secondary: Icon(
              isMasterSwitchOn
                  ? Icons.notifications_active
                  : Icons.notifications_off,
            ),
            title: Text(l10n.notifications),
            subtitle: Text(
              isMasterSwitchOn
                  ? l10n.notificationPermissionGrantedDescription
                  : l10n.notificationPermissionDeniedDescription,
            ),
            value: isMasterSwitchOn,
            onChanged: (value) async {
              if (value && !preferences.systemPermissionGranted) {
                // Need to request permission first
                await _handlePermissionRequest();
              } else {
                // Toggle all notifications
                ref
                    .read(notificationSettingsViewModelProvider.notifier)
                    .toggleAllNotifications(value);
              }
            },
          ),

          const Divider(),

          // Notification Types Section
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Text(
              l10n.notificationTypes,
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Tagging Notifications
          SwitchListTile(
            secondary: Icon(
              Icons.local_offer,
              color: isMasterSwitchOn
                  ? null
                  : Theme
                  .of(context)
                  .disabledColor,
            ),
            title: Text(l10n.taggingNotifications),
            subtitle: Text(l10n.taggingNotificationsDescription),
            value: preferences.taggingNotificationsEnabled,
            onChanged: isMasterSwitchOn
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
              color: isMasterSwitchOn
                  ? null
                  : Theme
                  .of(context)
                  .disabledColor,
            ),
            title: Text(l10n.directMessageNotifications),
            subtitle: Text(l10n.directMessageNotificationsDescription),
            value: preferences.directMessageNotificationsEnabled,
            onChanged: isMasterSwitchOn
                ? (value) {
              ref
                  .read(notificationSettingsViewModelProvider
                  .notifier)
                  .toggleDirectMessageNotifications(value);
            }
                : null,
          ),

          // Info message when master switch is disabled
          if (!isMasterSwitchOn)
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
