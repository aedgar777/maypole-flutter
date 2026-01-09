import 'package:flutter/material.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

/// A reusable error dialog that displays error messages to the user.
/// 
/// Shows an error icon, title, and message with a dismiss button.
class ErrorDialog {
  /// Shows an error dialog with the given error message.
  /// 
  /// [context] - The build context
  /// [error] - The error object or message to display
  /// [title] - Optional custom title (defaults to localized "Error")
  static Future<void> show(BuildContext context,
      dynamic error, {
        String? title,
      }) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .error,
                ),
                const SizedBox(width: 8),
                Text(title ?? l10n.errorTitle),
              ],
            ),
            content: Text(
              _formatError(error, l10n),
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.dismiss),
              ),
            ],
          ),
    );
  }

  /// Formats the error object into a readable string.
  static String _formatError(dynamic error, [AppLocalizations? l10n]) {
    if (error == null) {
      return l10n?.unknownError ?? 'An unknown error occurred';
    }

    // If it's already a string, return it
    if (error is String) {
      return error;
    }

    // For other error types, convert to string
    return error.toString();
  }
}
