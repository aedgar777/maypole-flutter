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
      barrierDismissible: true, // Allow dismissing by tapping outside
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

    // For Exception objects, try to extract the message
    if (error is Exception) {
      final errorString = error.toString();
      
      // If it's a generic Exception with a message, the toString() usually
      // returns "Exception: message" - we want to extract just the message
      // But on web with minified code, it may return "Instance of 'minified:xxx'"
      if (errorString.startsWith('Instance of')) {
        // Try to get the message through runtimeType or just return a generic message
        // Check if this is a specific exception type we can identify
        final typeName = error.runtimeType.toString();
        
        // If it's a plain Exception (not a subclass), try to get more info
        if (typeName == 'Exception' || typeName == '_Exception') {
          // Last resort - return a generic message suggesting to check console
          return l10n?.unknownError ?? 
            'An error occurred. Please check the browser console for details or try again.';
        }
        
        // For other exception types, include the type name
        return '$typeName: An error occurred while processing your request.';
      }
      
      // Remove "Exception: " prefix if present for cleaner display
      if (errorString.startsWith('Exception: ')) {
        return errorString.substring(11);
      }
      
      return errorString;
    }

    // For Error objects (like FlutterError), extract the message
    if (error is Error) {
      final errorString = error.toString();
      
      // Check for minified instance output
      if (errorString.startsWith('Instance of')) {
        return '${error.runtimeType}: An unexpected error occurred.';
      }
      
      return errorString;
    }

    // For any other type, convert to string but handle minified output
    final stringOutput = error.toString();
    if (stringOutput.startsWith('Instance of')) {
      return 'An unexpected error occurred. Please try again.';
    }
    
    return stringOutput;
  }
}
