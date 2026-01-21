import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/platform_info.dart';

/// A class to access environment-specific variables.
///
/// This class reads the `ENVIRONMENT` variable from the .env file
/// and provides the correct keys based on whether the app is in
/// 'prod' or 'dev' mode.
class AppConfig {
  static String get _environment {
    // Check dart-define first (baked into the compiled app at build time)
    const dartDefineEnv = String.fromEnvironment('ENVIRONMENT');
    if (dartDefineEnv.isNotEmpty) {
      return dartDefineEnv;
    }
    // Fall back to dotenv (used in web and local development)
    return dotenv.env['ENVIRONMENT'] ?? 'dev';
  }

  /// Returns true if the app is running on desktop platforms (Windows, Linux, macOS).
  static bool get isDesktop {
    return PlatformInfo.isDesktop;
  }

  /// Returns true if the app is running on desktop or web (typically wide screen devices).
  static bool get isWideScreen {
    return PlatformInfo.isWideScreen;
  }

  /// Returns true if the current environment is production.
  static bool get isProduction => _environment.toLowerCase() == 'prod' || _environment.toLowerCase() == 'production';

  /// Provides the correct Firebase Web API key based on the environment.
  static String get firebaseWebApiKey {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_WEB_API_KEY'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_WEB_API_KEY'] ?? '';
    }
  }

  /// Provides the correct Firebase Web App ID based on the environment.
  static String get firebaseWebAppId {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_WEB_APP_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_WEB_APP_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase Web Measurement ID based on the environment.
  static String get firebaseWebMeasurementId {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_WEB_MEASUREMENT_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_WEB_MEASUREMENT_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase Android API key based on the environment.
  static String get firebaseAndroidApiKey {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_ANDROID_API_KEY'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_ANDROID_API_KEY'] ?? '';
    }
  }

  /// Provides the correct Firebase Android App ID based on the environment.
  static String get firebaseAndroidAppId {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_ANDROID_APP_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_ANDROID_APP_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase iOS API key based on the environment.
  static String get firebaseIosApiKey {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_IOS_API_KEY'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_IOS_API_KEY'] ?? '';
    }
  }

  /// Provides the correct Firebase iOS App ID based on the environment.
  static String get firebaseIosAppId {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_IOS_APP_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_IOS_APP_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase Messaging Sender ID based on the environment.
  static String get firebaseMessagingSenderId {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_MESSAGING_SENDER_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_MESSAGING_SENDER_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase Project ID based on the environment.
  static String get firebaseProjectId {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_PROJECT_ID'] ?? 'maypole-flutter-ce6c3';
    } else {
      return dotenv.env['FIREBASE_DEV_PROJECT_ID'] ?? 'maypole-flutter-dev';
    }
  }

  /// Provides the correct Firebase Auth Domain based on the environment.
  static String get firebaseAuthDomain {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_AUTH_DOMAIN'] ?? 'maypole-flutter-ce6c3.firebaseapp.com';
    } else {
      return dotenv.env['FIREBASE_DEV_AUTH_DOMAIN'] ?? 'maypole-flutter-dev.firebaseapp.com';
    }
  }

  /// Provides the correct Firebase Storage Bucket based on the environment.
  static String get firebaseStorageBucket {
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_STORAGE_BUCKET'] ?? 'maypole-flutter-ce6c3.firebasestorage.app';
    } else {
      return dotenv.env['FIREBASE_DEV_STORAGE_BUCKET'] ?? 'maypole-flutter-dev.firebasestorage.app';
    }
  }

  /// Provides the correct Firebase Windows App ID for production.
  static String get firebaseWindowsAppId {
    return dotenv.env['FIREBASE_PROD_WINDOWS_APP_ID'] ?? '';
  }

  /// Provides the correct Firebase Windows Measurement ID for production.
  static String get firebaseWindowsMeasurementId {
    return dotenv.env['FIREBASE_PROD_WINDOWS_MEASUREMENT_ID'] ?? '';
  }

  /// Provides the iOS Bundle ID.
  static String get iosBundleId {
    return dotenv.env['IOS_BUNDLE_ID'] ?? 'app.maypole.maypole';
  }

  /// Provides the correct Google Places API key based on the environment.
  static String get googlePlacesApiKey {
    // First check dart-define (used in web builds)
    const dartDefineKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      debugPrint('🔑 Using Google Places API key from dart-define');
      return dartDefineKey;
    }

    // Fall back to dotenv
    // Use web-specific key for web platform if available
    if (kIsWeb) {
      if (isProduction) {
        debugPrint('🔑 Using Google Places API key: WEB PROD (isProduction=$isProduction, _environment=$_environment)');
        final webKey = dotenv.env['GOOGLE_PLACES_WEB_PROD_API_KEY'];
        if (webKey != null && webKey.isNotEmpty) return webKey;
        return dotenv.env['GOOGLE_PLACES_PROD_API_KEY'] ?? '';
      } else {
        debugPrint('🔑 Using Google Places API key: WEB DEV (isProduction=$isProduction, _environment=$_environment)');
        final webKey = dotenv.env['GOOGLE_PLACES_WEB_DEV_API_KEY'];
        if (webKey != null && webKey.isNotEmpty) return webKey;
        return dotenv.env['GOOGLE_PLACES_DEV_API_KEY'] ?? '';
      }
    }
    
    // Mobile platforms
    if (isProduction) {
      debugPrint('🔑 Using Google Places API key: MOBILE PROD (isProduction=$isProduction, _environment=$_environment)');
      return dotenv.env['GOOGLE_PLACES_PROD_API_KEY'] ?? '';
    } else {
      debugPrint('🔑 Using Google Places API key: MOBILE DEV (isProduction=$isProduction, _environment=$_environment)');
      return dotenv.env['GOOGLE_PLACES_DEV_API_KEY'] ?? '';
    }
  }

  /// Provides the correct Cloud Functions URL based on the environment.
  static String get cloudFunctionsUrl {
    // First check dart-define (used in web builds)
    const dartDefineUrl = String.fromEnvironment('CLOUD_FUNCTIONS_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }

    // Fall back to dotenv
    final url = isProduction
        ? dotenv.env['CLOUD_FUNCTIONS_PROD_URL']
        : dotenv.env['CLOUD_FUNCTIONS_DEV_URL'];
    
    if (url != null && url.isNotEmpty) {
      return url;
    }
    
    // Hardcoded fallback for web builds (where .env is not available)
    if (kIsWeb) {
      return isProduction
          ? 'https://places-autocomplete-1069925301177.us-central1.run.app'
          : 'https://places-autocomplete-n7tnn27vga-uc.a.run.app';
    }
    
    return '';
  }

  /// Provides the app's base URL for sharing/deeplinks based on the environment.
  static String get appUrl {
    // First check dart-define (used in builds)
    const dartDefineUrl = String.fromEnvironment('APP_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }

    // Fall back to environment-specific dotenv values
    if (isProduction) {
      return dotenv.env['APP_URL_PROD'] ?? 'https://maypole.app';
    } else {
      return dotenv.env['APP_URL_DEV'] ?? 'https://maypole-flutter-dev.web.app';
    }
  }
}
