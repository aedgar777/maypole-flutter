import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

/// Utility functions for screen-related calculations.
class ScreenUtils {
  /// The minimum width threshold to be considered a "wide screen" (tablet/desktop).
  static const double wideScreenThreshold = 600;

  /// Returns true if the given [constraints] indicate a wide screen layout.
  ///
  /// This is intended to be used within a [LayoutBuilder] to make responsive
  /// layout decisions based on the available width.
  ///
  /// Example usage:
  /// ```dart
  /// LayoutBuilder(
  ///   builder: (context, constraints) {
  ///     final isWide = ScreenUtils.isWideScreen(constraints);
  ///     // ... responsive layout logic
  ///   },
  /// )
  /// ```
  static bool isWideScreen(BoxConstraints constraints) {
    return constraints.maxWidth >= wideScreenThreshold;
  }

  /// Returns true if the screen is considered "wide" based on [BuildContext].
  ///
  /// This is intended to be used when a [LayoutBuilder] is not available.
  /// On web, this always returns true for responsive web layouts.
  ///
  /// Example usage:
  /// ```dart
  /// final isWide = ScreenUtils.isWideScreenFromContext(context);
  /// ```
  static bool isWideScreenFromContext(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= wideScreenThreshold || kIsWeb;
  }

  /// Returns true if the screen is considered "wide" based on screen width.
  ///
  /// On web, this always returns true for responsive web layouts.
  static bool isWideScreenFromWidth(double width) {
    return width >= wideScreenThreshold || kIsWeb;
  }

  /// Returns true only for iOS devices.
  static bool get isIOS {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Parses and returns the iOS major version (for example, `18`), if available.
  static int? getiOSMajorVersion() {
    if (!isIOS) return null;

    final versionString = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+)').firstMatch(versionString);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// Shows an in-app AppBar back button only for legacy iOS versions that
  /// don't support swipe-to-go-back. Never shows on Android/web.
  static bool shouldShowAppBarBackButton({
    int swipeBackSupportedFromIOSMajor = 7,
  }) {
    if (!isIOS) return false;

    final majorVersion = getiOSMajorVersion();
    if (majorVersion == null) {
      // Default to no explicit AppBar back button when version is unknown.
      return false;
    }

    return majorVersion < swipeBackSupportedFromIOSMajor;
  }
}
