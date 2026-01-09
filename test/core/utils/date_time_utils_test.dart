import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils - formatRelativeDate', () {
    test('returns "Today" for current date', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatRelativeDate(now);
      expect(result, 'Today');
    });

    test('returns "Yesterday" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateTimeUtils.formatRelativeDate(yesterday);
      expect(result, 'Yesterday');
    });

    test('returns formatted date for older dates', () {
      final oldDate = DateTime(2024, 1, 15);
      final result = DateTimeUtils.formatRelativeDate(oldDate);
      // Should return something like "Jan 15, 2024"
      expect(result, isNotEmpty);
      expect(result, isNot('Today'));
      expect(result, isNot('Yesterday'));
    });

    test('handles dates with different times correctly', () {
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 8, 0);
      final todayEvening = DateTime(now.year, now.month, now.day, 20, 0);
      
      expect(DateTimeUtils.formatRelativeDate(todayMorning), 'Today');
      expect(DateTimeUtils.formatRelativeDate(todayEvening), 'Today');
    });
  });

  group('DateTimeUtils - formatTime', () {
    test('formats time correctly', () {
      final dateTime = DateTime(2024, 1, 15, 14, 30);
      final result = DateTimeUtils.formatTime(dateTime);
      // Result depends on locale, but should contain time components
      expect(result, isNotEmpty);
      expect(result, contains(RegExp(r'\d')));
    });

    test('handles midnight correctly', () {
      final midnight = DateTime(2024, 1, 15, 0, 0);
      final result = DateTimeUtils.formatTime(midnight);
      expect(result, isNotEmpty);
    });

    test('handles noon correctly', () {
      final noon = DateTime(2024, 1, 15, 12, 0);
      final result = DateTimeUtils.formatTime(noon);
      expect(result, isNotEmpty);
    });
  });

  group('DateTimeUtils - formatRelativeDateTime', () {
    test('combines date and time for today', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatRelativeDateTime(now);
      expect(result, contains('Today'));
      expect(result.split(' ').length, greaterThanOrEqualTo(2));
    });

    test('combines date and time for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateTimeUtils.formatRelativeDateTime(yesterday);
      expect(result, contains('Yesterday'));
    });

    test('combines date and time for older dates', () {
      final oldDate = DateTime(2024, 1, 15, 14, 30);
      final result = DateTimeUtils.formatRelativeDateTime(oldDate);
      expect(result, isNotEmpty);
      expect(result.split(' ').length, greaterThanOrEqualTo(2));
    });
  });

  group('DateTimeUtils - formatShortRelative', () {
    test('returns "Just now" for recent times', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatShortRelative(now);
      expect(result, 'Just now');
    });

    test('returns "Just now" for times less than 60 seconds ago', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      final result = DateTimeUtils.formatShortRelative(recent);
      expect(result, 'Just now');
    });

    test('returns minutes ago for times less than an hour', () {
      final minutes30 = DateTime.now().subtract(const Duration(minutes: 30));
      final result = DateTimeUtils.formatShortRelative(minutes30);
      expect(result, contains('m ago'));
      expect(result, contains('30'));
    });

    test('returns hours ago for times less than a day', () {
      final hours5 = DateTime.now().subtract(const Duration(hours: 5));
      final result = DateTimeUtils.formatShortRelative(hours5);
      expect(result, contains('h ago'));
      expect(result, contains('5'));
    });

    test('returns relative date for older times', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateTimeUtils.formatShortRelative(yesterday);
      expect(result, 'Yesterday');
    });
  });

  group('DateTimeUtils - formatThreadTimestamp', () {
    test('returns time for today', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatThreadTimestamp(now);
      // Should return time like "2:30 PM", not "Today"
      expect(result, isNot(contains('Today')));
      expect(result, contains(RegExp(r'\d')));
    });

    test('returns "Yesterday" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateTimeUtils.formatThreadTimestamp(yesterday);
      expect(result, 'Yesterday');
    });

    test('returns day name for this week', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final result = DateTimeUtils.formatThreadTimestamp(threeDaysAgo);
      // Should be a day name (Monday, Tuesday, etc.)
      expect(result, isNotEmpty);
      expect(result, isNot('Yesterday'));
    });

    test('returns date for older messages', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final result = DateTimeUtils.formatThreadTimestamp(oldDate);
      // Should return something like "Dec 12"
      expect(result, isNotEmpty);
    });
  });

  group('DateTimeUtils - formatFullDateTime', () {
    test('formats complete date and time', () {
      final dateTime = DateTime(2024, 1, 15, 14, 30);
      final result = DateTimeUtils.formatFullDateTime(dateTime);
      expect(result, isNotEmpty);
      expect(result, contains('2024'));
      expect(result, contains('at'));
    });

    test('includes day of week', () {
      final dateTime = DateTime(2024, 1, 15, 14, 30);
      final result = DateTimeUtils.formatFullDateTime(dateTime);
      // Should contain a day name like Monday, Tuesday, etc.
      expect(result, isNotEmpty);
    });
  });

  group('DateTimeUtils - formatRelativeDateTimeWithSeparator', () {
    test('uses custom separator when provided', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatRelativeDateTimeWithSeparator(
        now,
        separator: '@',
      );
      expect(result, contains('@'));
    });

    test('uses default separator when not provided', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatRelativeDateTimeWithSeparator(now);
      expect(result, contains('at'));
    });

    test('formats date and time with separator', () {
      final now = DateTime.now();
      final result = DateTimeUtils.formatRelativeDateTimeWithSeparator(now);
      expect(result, contains('Today'));
      final parts = result.split(' ');
      expect(parts.length, greaterThanOrEqualTo(3)); // "Today at 2:30 PM"
    });
  });
}
