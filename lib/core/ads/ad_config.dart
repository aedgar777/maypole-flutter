import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maypole/core/services/remote_config_service.dart';

/// AdMob configuration for different ad unit IDs
/// Automatically detects environment and uses test ads in dev, production ads in prod.
/// 
/// Web ads are served via Adsterra (https://adsterra.com)
class AdConfig {
  /// Whether ads are enabled in the app
  /// Now controlled by Firebase Remote Config feature flag
  /// Fallback to true if Remote Config fails
  static bool get adsEnabled {
    try {
      return RemoteConfigService().adsEnabled;
    } catch (e) {
      return true; // Default to enabled if Remote Config fails
    }
  }
  
  /// Whether banner ads are enabled (can be controlled separately)
  static bool get bannerAdsEnabled {
    try {
      return RemoteConfigService().bannerAdsEnabled && adsEnabled;
    } catch (e) {
      return true;
    }
  }
  
  /// Whether interstitial ads are enabled (can be controlled separately)
  static bool get interstitialAdsEnabled {
    try {
      return RemoteConfigService().interstitialAdsEnabled && adsEnabled;
    } catch (e) {
      return true;
    }
  }
  
  /// Get interstitial ad frequency from Remote Config
  static int get interstitialFrequency {
    try {
      return RemoteConfigService().interstitialFrequency;
    } catch (e) {
      return 5; // Default: show every 5 location switches
    }
  }
  
  /// Whether web ads are enabled (locked behind master ads_enabled flag)
  static bool get webAdsEnabled {
    if (!adsEnabled) return false; // Must have master flag enabled
    try {
      return RemoteConfigService().webAdsEnabled;
    } catch (e) {
      return true; // Default to enabled if Remote Config fails
    }
  }

  /// Whether to use test ads
  /// Automatically determined based on environment (dev = test ads, prod = real ads)
  /// You can override this by setting a constant value instead
  static bool get useTestAds {
    // Check if we're in debug mode (always use test ads)
    if (kDebugMode) return true;
    
    // Check environment from build configuration
    const dartDefineEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    
    // Check environment from .env file
    String dotenvEnv = 'dev';
    try {
      dotenvEnv = dotenv.env['ENVIRONMENT'] ?? 'dev';
    } catch (e) {
      dotenvEnv = 'dev';
    }
    
    final environment = dartDefineEnv.isNotEmpty ? dartDefineEnv : dotenvEnv;
    
    // Use test ads for dev/development, real ads for prod/production
    return environment.toLowerCase() != 'production' && 
           environment.toLowerCase() != 'prod';
  }

  // Android Test Ad Unit IDs (provided by Google)
  static const String _testBannerAndroidId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAndroidId = 'ca-app-pub-3940256099942544/1033173712';

  // iOS Test Ad Unit IDs (provided by Google)
  static const String _testBannerIosId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialIosId = 'ca-app-pub-3940256099942544/4411468910';

  // Production Ad Unit IDs
  static const String _prodBannerAndroidId = 'ca-app-pub-9803674282352310/5272318950';
  static const String _prodBannerIosId = 'ca-app-pub-9803674282352310/5141931797';
  static const String _prodInterstitialAndroidId = 'ca-app-pub-9803674282352310/4782839146';
  static const String _prodInterstitialIosId = 'ca-app-pub-9803674282352310/1931662132';

  /// Get the banner ad unit ID for the current platform
  /// Web uses Android ad unit IDs by default
  static String get bannerAdUnitId {
    if (!adsEnabled) return '';
    
    if (useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS ? _testBannerIosId : _testBannerAndroidId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? _prodBannerIosId : _prodBannerAndroidId;
  }

  /// Get the interstitial ad unit ID for the current platform
  /// Web uses Android ad unit IDs by default
  static String get interstitialAdUnitId {
    if (!adsEnabled) return '';
    
    if (useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS ? _testInterstitialIosId : _testInterstitialAndroidId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? _prodInterstitialIosId : _prodInterstitialAndroidId;
  }

  /// AdMob App IDs (required in AndroidManifest.xml and Info.plist)
  static const String androidAppId = 'ca-app-pub-9803674282352310~3165030367';
  static const String iosAppId = 'ca-app-pub-9803674282352310~6862207571';

  // ==================== ADSTERRA WEB AD CONFIGURATION ====================
  
  /// Helper to check if we're in production environment
  static bool get _isProduction {
    // Check environment from build configuration
    const dartDefineEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    
    // Check environment from .env file
    String dotenvEnv = 'dev';
    try {
      dotenvEnv = dotenv.env['ENVIRONMENT'] ?? 'dev';
    } catch (e) {
      dotenvEnv = 'dev';
    }
    
    final environment = dartDefineEnv.isNotEmpty ? dartDefineEnv : dotenvEnv;
    return environment.toLowerCase() == 'production' || 
           environment.toLowerCase() == 'prod';
  }
  
  /// Adsterra Publisher ID - DEV (5613140 for maypole-flutter-dev.web.app)
  static const String _adsterraDevPublisherId = '5613140';
  
  /// Adsterra Publisher ID - PROD (5613117 for maypole.app)
  static const String _adsterraProdPublisherId = '5613117';
  
  /// Get the appropriate Adsterra Publisher ID for current environment
  static String get adsterraPublisherId => 
      _isProduction ? _adsterraProdPublisherId : _adsterraDevPublisherId;
  
  /// Adsterra DEV Slot ID for 728x90 Leaderboard Banner
  /// Used on maypole-flutter-dev.web.app
  static const String _adsterraDevLeaderboardSlot = '28635586';
  
  /// Adsterra PROD Slot ID for 728x90 Leaderboard Banner  
  /// Used on maypole.app
  static const String _adsterraProdLeaderboardSlot = '28635540';
  
  /// Get the appropriate Adsterra Slot ID for current environment
  static String get adsterraLeaderboardSlot => 
      _isProduction ? _adsterraProdLeaderboardSlot : _adsterraDevLeaderboardSlot;
  
  /// Adsterra Script Key - PROD (for slot 28635540)
  static const String _adsterraProdLeaderboardKey = '5f9bf870d30ef305b76bd374783acc7d';
  
  /// Adsterra Script Key - DEV (for slot 28635586)
  static const String _adsterraDevLeaderboardKey = '25512f1619501c99306a893e0937e5d8';
  
  /// Get the appropriate Adsterra Script Key for current environment
  static String get adsterraLeaderboardKey => 
      _isProduction ? _adsterraProdLeaderboardKey : _adsterraDevLeaderboardKey;
}
