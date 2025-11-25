import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class DateTimeUtils {
  /// Formats a DateTime to a human-readable relative date string.
  /// Returns "Today", "Yesterday", or a localized date format for older dates.
  /// If a BuildContext is provided, it will use localized strings.
  static String formatRelativeDate(DateTime dateTime, {
    String? locale,
    BuildContext? context,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return context != null
          ? AppLocalizations.of(context)!.today
          : 'Today';
    } else if (date == yesterday) {
      return context != null
          ? AppLocalizations.of(context)!.yesterday
          : 'Yesterday';
    } else {
      // Use localized date format for older dates
      final format = DateFormat.yMMMd(locale);
      return format.format(dateTime);
    }
  }

  /// Formats a DateTime to a localized abbreviated time string.
  /// Returns time in format like "3:45 PM" or "15:45" depending on locale.
  static String formatTime(DateTime dateTime, {String? locale}) {
    final format = DateFormat.jm(locale);
    return format.format(dateTime);
  }

  /// Combines relative date and time formatting for a complete timestamp.
  /// Returns strings like "Today 3:45 PM" or "Yesterday 10:30 AM" or "Jan 15, 2024 2:15 PM"
  static String formatRelativeDateTime(DateTime dateTime, {
    String? locale,
    BuildContext? context,
  }) {
    final date = formatRelativeDate(dateTime, locale: locale, context: context);
    final time = formatTime(dateTime, locale: locale);
    return '$date $time';
  }

  /// Formats a DateTime with a separator between date and time.
  /// Returns strings like "Today at 3:45 PM"
  static String formatRelativeDateTimeWithSeparator(DateTime dateTime, {
    String? separator,
    String? locale,
    BuildContext? context,
  }) {
    final date = formatRelativeDate(dateTime, locale: locale, context: context);
    final time = formatTime(dateTime, locale: locale);
    final sep = separator ?? (context != null
        ? AppLocalizations.of(context)!.at
        : 'at');
    return '$date $sep $time';
  }

  /// Returns a short relative time string for very recent times.
  /// Returns "Just now", "2m ago", "1h ago", or falls back to date/time for older messages.
  static String formatShortRelative(DateTime dateTime, {
    String? locale,
    BuildContext? context,
  }) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return context != null
          ? AppLocalizations.of(context)!.justNow
          : 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return context != null
          ? AppLocalizations.of(context)!.minutesAgo(minutes)
          : '${minutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return context != null
          ? AppLocalizations.of(context)!.hoursAgo(hours)
          : '${hours}h ago';
    } else {
      return formatRelativeDate(dateTime, locale: locale, context: context);
    }
  }
}
