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
    try {
      return dotenv.env['ENVIRONMENT'] ?? 'dev';
    } catch (e) {
      debugPrint('⚠️ Error accessing dotenv for ENVIRONMENT: $e');
      return 'dev';
    }
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
    // Try dart-define first (used in production builds)
    const prodKey = String.fromEnvironment('FIREBASE_PROD_WEB_API_KEY');
    const devKey = String.fromEnvironment('FIREBASE_DEV_WEB_API_KEY');
    
    if (isProduction && prodKey.isNotEmpty) return prodKey;
    if (!isProduction && devKey.isNotEmpty) return devKey;
    
    // Fall back to dotenv for local development
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_WEB_API_KEY'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_WEB_API_KEY'] ?? '';
    }
  }

  /// Provides the correct Firebase Web App ID based on the environment.
  static String get firebaseWebAppId {
    // Try dart-define first (used in production builds)
    const prodId = String.fromEnvironment('FIREBASE_PROD_WEB_APP_ID');
    const devId = String.fromEnvironment('FIREBASE_DEV_WEB_APP_ID');
    
    if (isProduction && prodId.isNotEmpty) return prodId;
    if (!isProduction && devId.isNotEmpty) return devId;
    
    // Fall back to dotenv for local development
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_WEB_APP_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_WEB_APP_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase Web Measurement ID based on the environment.
  static String get firebaseWebMeasurementId {
    // Try dart-define first (used in production builds)
    const prodId = String.fromEnvironment('FIREBASE_PROD_WEB_MEASUREMENT_ID');
    const devId = String.fromEnvironment('FIREBASE_DEV_WEB_MEASUREMENT_ID');
    
    if (isProduction && prodId.isNotEmpty) return prodId;
    if (!isProduction && devId.isNotEmpty) return devId;
    
    // Fall back to dotenv for local development
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
    // Try dart-define first (used in production builds)
    const prodId = String.fromEnvironment('FIREBASE_PROD_MESSAGING_SENDER_ID');
    const devId = String.fromEnvironment('FIREBASE_DEV_MESSAGING_SENDER_ID');
    
    if (isProduction && prodId.isNotEmpty) return prodId;
    if (!isProduction && devId.isNotEmpty) return devId;
    
    // Fall back to dotenv for local development
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_MESSAGING_SENDER_ID'] ?? '';
    } else {
      return dotenv.env['FIREBASE_DEV_MESSAGING_SENDER_ID'] ?? '';
    }
  }

  /// Provides the correct Firebase Project ID based on the environment.
  static String get firebaseProjectId {
    // Try dart-define first (used in production builds)
    const prodId = String.fromEnvironment('FIREBASE_PROD_PROJECT_ID');
    const devId = String.fromEnvironment('FIREBASE_DEV_PROJECT_ID');
    
    if (isProduction && prodId.isNotEmpty) return prodId;
    if (!isProduction && devId.isNotEmpty) return devId;
    
    // Fall back to dotenv for local development
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_PROJECT_ID'] ?? 'maypole-flutter-ce6c3';
    } else {
      return dotenv.env['FIREBASE_DEV_PROJECT_ID'] ?? 'maypole-flutter-dev';
    }
  }

  /// Provides the correct Firebase Auth Domain based on the environment.
  static String get firebaseAuthDomain {
    // Try dart-define first (used in production builds)
    const prodDomain = String.fromEnvironment('FIREBASE_PROD_AUTH_DOMAIN');
    const devDomain = String.fromEnvironment('FIREBASE_DEV_AUTH_DOMAIN');
    
    if (isProduction && prodDomain.isNotEmpty) return prodDomain;
    if (!isProduction && devDomain.isNotEmpty) return devDomain;
    
    // Fall back to dotenv for local development
    if (isProduction) {
      return dotenv.env['FIREBASE_PROD_AUTH_DOMAIN'] ?? 'maypole-flutter-ce6c3.firebaseapp.com';
    } else {
      return dotenv.env['FIREBASE_DEV_AUTH_DOMAIN'] ?? 'maypole-flutter-dev.firebaseapp.com';
    }
  }

  /// Provides the correct Firebase Storage Bucket based on the environment.
  static String get firebaseStorageBucket {
    // Try dart-define first (used in production builds)
    const prodBucket = String.fromEnvironment('FIREBASE_PROD_STORAGE_BUCKET');
    const devBucket = String.fromEnvironment('FIREBASE_DEV_STORAGE_BUCKET');
    
    if (isProduction && prodBucket.isNotEmpty) return prodBucket;
    if (!isProduction && devBucket.isNotEmpty) return devBucket;
    
    // Fall back to dotenv for local development
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
    try {
      // First check dart-define (used in web builds)
      const dartDefineKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
      if (dartDefineKey.isNotEmpty) {
        return dartDefineKey;
      }

      // Fall back to dotenv
      // Use web-specific key for web platform if available
      if (kIsWeb) {
        if (isProduction) {
          final webKey = dotenv.env['GOOGLE_PLACES_WEB_PROD_API_KEY'];
          if (webKey != null && webKey.isNotEmpty) return webKey;
          return dotenv.env['GOOGLE_PLACES_PROD_API_KEY'] ?? '';
        } else {
          final webKey = dotenv.env['GOOGLE_PLACES_WEB_DEV_API_KEY'];
          if (webKey != null && webKey.isNotEmpty) return webKey;
          return dotenv.env['GOOGLE_PLACES_DEV_API_KEY'] ?? '';
        }
      }
      
      // Mobile platforms
      if (isProduction) {
        return dotenv.env['GOOGLE_PLACES_PROD_API_KEY'] ?? '';
      } else {
        return dotenv.env['GOOGLE_PLACES_DEV_API_KEY'] ?? '';
      }
    } catch (e) {
      debugPrint('⚠️ Error accessing dotenv for Google Places API key: $e');
      return '';
    }
  }

  /// Provides the correct Cloud Functions URL based on the environment.
  static String get cloudFunctionsUrl {
    return _getCloudFunctionUrl('autocomplete');
  }
  
  /// Provides the Cloud Function URL for place details endpoint.
  static String get cloudFunctionsPlaceDetailsUrl {
    return _getCloudFunctionUrl('placeDetails');
  }
  
  /// Provides the Cloud Function URL for reverse geocoding endpoint.
  static String get cloudFunctionsReverseGeocodeUrl {
    return _getCloudFunctionUrl('reverseGeocode');
  }
  
  /// Helper to get Cloud Function URL by endpoint name.
  static String _getCloudFunctionUrl(String endpoint) {
    try {
      // First check dart-define (used in web builds)
      final dartDefineUrl = String.fromEnvironment('CLOUD_FUNCTIONS_${endpoint.toUpperCase()}_URL');
      if (dartDefineUrl.isNotEmpty) {
        return dartDefineUrl;
      }

      // Fall back to dotenv
      final envVarName = isProduction
          ? 'CLOUD_FUNCTIONS_${endpoint.toUpperCase()}_PROD_URL'
          : 'CLOUD_FUNCTIONS_${endpoint.toUpperCase()}_DEV_URL';
      final url = dotenv.env[envVarName];
      
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (e) {
      // Continue to fallback
    }
    
    // Hardcoded fallbacks for web builds (where .env is not available)
    if (kIsWeb) {
      // These are the default Cloud Run URLs based on function names
      if (isProduction) {
        switch (endpoint) {
          case 'autocomplete':
            return 'https://places-autocomplete-1069925301177.us-central1.run.app';
          case 'placeDetails':
            return 'https://places-place-details-1069925301177.us-central1.run.app';
          case 'reverseGeocode':
            return 'https://places-reverse-geocode-1069925301177.us-central1.run.app';
          default:
            return '';
        }
      } else {
        switch (endpoint) {
          case 'autocomplete':
            return 'https://places-autocomplete-n7tnn27vga-uc.a.run.app';
          case 'placeDetails':
            return 'https://places-place-details-n7tnn27vga-uc.a.run.app';
          case 'reverseGeocode':
            return 'https://places-reverse-geocode-n7tnn27vga-uc.a.run.app';
          default:
            return '';
        }
      }
    }
    
    return '';
  }

  /// Provides the app's base URL for sharing/deeplinks based on the environment.
  static String get appUrl {
    try {
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
    } catch (e) {
      debugPrint('⚠️ Error accessing dotenv for appUrl: $e');
      return 'https://maypole.app';
    }
  }
}
