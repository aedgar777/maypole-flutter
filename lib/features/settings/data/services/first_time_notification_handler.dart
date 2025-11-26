import 'package:flutter/material.dart';
import 'package:maypole/features/settings/data/services/notification_service.dart';

/// Handles requesting notification permissions on first app use (after login/registration)
class FirstTimeNotificationHandler {
  final NotificationService _notificationService;

  FirstTimeNotificationHandler(this._notificationService);

  /// Request notification permission if this is the first time
  /// Shows a contextual dialog before asking for system permission
  /// 
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestPermissionIfNeeded(BuildContext context) async {
    final hasAsked = await _notificationService.hasAskedForPermission();

    if (hasAsked) {
      debugPrint('Already asked for notification permission, skipping...');
      return await _notificationService.checkNotificationPermission();
    }

    debugPrint('First time - requesting notification permission...');

    // Show contextual dialog explaining why we need notifications
    if (context.mounted) {
      final shouldAsk = await _showPermissionRationaleDialog(context);

      if (!shouldAsk) {
        debugPrint('User declined to see permission dialog');
        // Still mark as asked even if they declined the rationale
        await _notificationService.requestNotificationPermission(
            markAsAsked: true);
        return false;
      }
    }

    // Request the system permission
    return await _notificationService.requestNotificationPermission();
  }

  /// Show a dialog explaining why we need notification permission
  Future<bool> _showPermissionRationaleDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.notifications_active, size: 48),
          title: const Text('Stay Connected'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable notifications to stay updated with:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _NotificationFeatureRow(
                  icon: Icons.local_offer,
                  title: 'Tags',
                  description: 'When someone mentions you in a conversation',
                ),
                SizedBox(height: 12),
                _NotificationFeatureRow(
                  icon: Icons.message,
                  title: 'Direct Messages',
                  description: 'When you receive a new message',
                ),
                SizedBox(height: 16),
                Text(
                  'You can customize these preferences anytime in Settings.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable Notifications'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Request permission silently (without showing rationale dialog)
  /// Useful for testing or when you want to request immediately
  Future<bool> requestPermissionSilently() async {
    return await _notificationService.requestPermissionOnFirstUse();
  }
}

/// Widget for displaying a notification feature in the rationale dialog
class _NotificationFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _NotificationFeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
