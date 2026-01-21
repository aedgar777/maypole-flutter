/// Platform-aware web ad widget
/// Uses conditional exports to provide web-specific implementation on web
/// and stub implementation on other platforms (iOS, Android, macOS, etc.)
export 'web_ad_widget_stub.dart'
    if (dart.library.js_util) 'web_ad_widget_web.dart';
