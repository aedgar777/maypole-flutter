import 'dart:io';

/// IO implementation for platform detection (mobile/desktop)
class PlatformInfo {
  static bool get isDesktop {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static bool get isWideScreen {
    return isDesktop;
  }
}
