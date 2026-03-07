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
}
