/// Represents user notification preferences stored locally
class NotificationPreferences {
  /// Whether tagging notifications are enabled
  final bool taggingNotificationsEnabled;

  /// Whether direct message notifications are enabled
  final bool directMessageNotificationsEnabled;

  /// Whether the system notification permission has been granted
  final bool systemPermissionGranted;

  const NotificationPreferences({
    this.taggingNotificationsEnabled = true,
    this.directMessageNotificationsEnabled = true,
    this.systemPermissionGranted = false,
  });

  NotificationPreferences copyWith({
    bool? taggingNotificationsEnabled,
    bool? directMessageNotificationsEnabled,
    bool? systemPermissionGranted,
  }) {
    return NotificationPreferences(
      taggingNotificationsEnabled: taggingNotificationsEnabled ??
          this.taggingNotificationsEnabled,
      directMessageNotificationsEnabled: directMessageNotificationsEnabled ??
          this.directMessageNotificationsEnabled,
      systemPermissionGranted: systemPermissionGranted ??
          this.systemPermissionGranted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taggingNotificationsEnabled': taggingNotificationsEnabled,
      'directMessageNotificationsEnabled': directMessageNotificationsEnabled,
      'systemPermissionGranted': systemPermissionGranted,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      taggingNotificationsEnabled: json['taggingNotificationsEnabled'] as bool? ??
          true,
      directMessageNotificationsEnabled: json['directMessageNotificationsEnabled'] as bool? ??
          true,
      systemPermissionGranted: json['systemPermissionGranted'] as bool? ??
          false,
    );
  }
}
