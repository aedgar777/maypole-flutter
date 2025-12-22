import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/settings/domain/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('creates instance with default values', () {
      const prefs = NotificationPreferences();

      expect(prefs.taggingNotificationsEnabled, isTrue);
      expect(prefs.directMessageNotificationsEnabled, isTrue);
      expect(prefs.systemPermissionGranted, isFalse);
    });

    test('creates instance with custom values', () {
      const prefs = NotificationPreferences(
        taggingNotificationsEnabled: false,
        directMessageNotificationsEnabled: false,
        systemPermissionGranted: true,
      );

      expect(prefs.taggingNotificationsEnabled, isFalse);
      expect(prefs.directMessageNotificationsEnabled, isFalse);
      expect(prefs.systemPermissionGranted, isTrue);
    });

    test('copyWith creates new instance with updated values', () {
      const original = NotificationPreferences(
        taggingNotificationsEnabled: true,
        directMessageNotificationsEnabled: true,
        systemPermissionGranted: false,
      );

      final updated = original.copyWith(
        taggingNotificationsEnabled: false,
      );

      expect(updated.taggingNotificationsEnabled, isFalse);
      expect(updated.directMessageNotificationsEnabled, isTrue);
      expect(updated.systemPermissionGranted, isFalse);
    });

    test('copyWith with no parameters returns same values', () {
      const original = NotificationPreferences(
        taggingNotificationsEnabled: false,
        directMessageNotificationsEnabled: true,
        systemPermissionGranted: true,
      );

      final copy = original.copyWith();

      expect(copy.taggingNotificationsEnabled, original.taggingNotificationsEnabled);
      expect(copy.directMessageNotificationsEnabled, original.directMessageNotificationsEnabled);
      expect(copy.systemPermissionGranted, original.systemPermissionGranted);
    });

    test('copyWith can update multiple fields', () {
      const original = NotificationPreferences();

      final updated = original.copyWith(
        taggingNotificationsEnabled: false,
        directMessageNotificationsEnabled: false,
        systemPermissionGranted: true,
      );

      expect(updated.taggingNotificationsEnabled, isFalse);
      expect(updated.directMessageNotificationsEnabled, isFalse);
      expect(updated.systemPermissionGranted, isTrue);
    });

    test('toJson serializes correctly', () {
      const prefs = NotificationPreferences(
        taggingNotificationsEnabled: false,
        directMessageNotificationsEnabled: true,
        systemPermissionGranted: true,
      );

      final json = prefs.toJson();

      expect(json['taggingNotificationsEnabled'], isFalse);
      expect(json['directMessageNotificationsEnabled'], isTrue);
      expect(json['systemPermissionGranted'], isTrue);
      expect(json.length, 3);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'taggingNotificationsEnabled': false,
        'directMessageNotificationsEnabled': true,
        'systemPermissionGranted': true,
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.taggingNotificationsEnabled, isFalse);
      expect(prefs.directMessageNotificationsEnabled, isTrue);
      expect(prefs.systemPermissionGranted, isTrue);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.taggingNotificationsEnabled, isTrue);
      expect(prefs.directMessageNotificationsEnabled, isTrue);
      expect(prefs.systemPermissionGranted, isFalse);
    });

    test('fromJson uses defaults for null values', () {
      final json = {
        'taggingNotificationsEnabled': null,
        'directMessageNotificationsEnabled': null,
        'systemPermissionGranted': null,
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.taggingNotificationsEnabled, isTrue);
      expect(prefs.directMessageNotificationsEnabled, isTrue);
      expect(prefs.systemPermissionGranted, isFalse);
    });

    test('serialization round-trip preserves data', () {
      const original = NotificationPreferences(
        taggingNotificationsEnabled: false,
        directMessageNotificationsEnabled: false,
        systemPermissionGranted: true,
      );

      final json = original.toJson();
      final restored = NotificationPreferences.fromJson(json);

      expect(restored.taggingNotificationsEnabled, original.taggingNotificationsEnabled);
      expect(restored.directMessageNotificationsEnabled, original.directMessageNotificationsEnabled);
      expect(restored.systemPermissionGranted, original.systemPermissionGranted);
    });

    test('handles all possible boolean combinations', () {
      final combinations = [
        [true, true, true],
        [true, true, false],
        [true, false, true],
        [true, false, false],
        [false, true, true],
        [false, true, false],
        [false, false, true],
        [false, false, false],
      ];

      for (final combo in combinations) {
        final prefs = NotificationPreferences(
          taggingNotificationsEnabled: combo[0],
          directMessageNotificationsEnabled: combo[1],
          systemPermissionGranted: combo[2],
        );

        final json = prefs.toJson();
        final restored = NotificationPreferences.fromJson(json);

        expect(restored.taggingNotificationsEnabled, combo[0]);
        expect(restored.directMessageNotificationsEnabled, combo[1]);
        expect(restored.systemPermissionGranted, combo[2]);
      }
    });
  });
}
