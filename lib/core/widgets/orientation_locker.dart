import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/screen_utils.dart';

/// Locks the device to portrait orientation when the screen is narrow
/// (mobile phone or small browser window), and allows all orientations
/// on wide screens (tablets, desktop, large browser windows).
///
/// Wrap the root of your widget tree with this to enforce orientation
/// restrictions based on screen width.
class OrientationLocker extends StatefulWidget {
  final Widget child;

  const OrientationLocker({super.key, required this.child});

  @override
  State<OrientationLocker> createState() => _OrientationLockerState();
}

class _OrientationLockerState extends State<OrientationLocker> {
  /// Tracks the last known narrow/wide state to avoid redundant
  /// calls to [SystemChrome.setPreferredOrientations].
  bool? _lastIsNarrow;

  @override
  void dispose() {
    // Restore all orientations when this widget is removed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _updateOrientation(bool isNarrow) {
    if (_lastIsNarrow == isNarrow) return;
    _lastIsNarrow = isNarrow;

    if (isNarrow) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            constraints.maxWidth < ScreenUtils.wideScreenThreshold;

        // Schedule orientation update after the current frame to avoid
        // calling system methods during the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateOrientation(isNarrow);
        });

        return widget.child;
      },
    );
  }
}
