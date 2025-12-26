import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Custom toast/snackbar utility that provides native-looking feedback
/// with better styling that matches the app's theme
class AppToast {
  /// Show a success toast with green accent
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFF1E1E1E),
      iconColor: Colors.green,
    );
  }

  /// Show an info toast with blue accent
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFF1E1E1E),
      iconColor: Colors.blue,
    );
  }

  /// Show a warning toast with orange accent
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_outlined,
      backgroundColor: const Color(0xFF1E1E1E),
      iconColor: Colors.orange,
    );
  }

  /// Show an error toast with red accent
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: const Color(0xFF1E1E1E),
      iconColor: Colors.red,
    );
  }

  /// Internal method to show the styled snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      margin: EdgeInsets.only(
        bottom: _getBottomMargin(context),
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      elevation: 8,
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Calculate bottom margin based on platform for native-like positioning
  static double _getBottomMargin(BuildContext context) {
    if (kIsWeb) {
      return 16;
    }

    // On mobile, position above navigation bar if present
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    if (bottomPadding > 0) {
      return bottomPadding + 8;
    }

    return 16;
  }
}
