import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Firebase Remote Config
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ Remote Config already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing Firebase Remote Config...');
      
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode 
            ? const Duration(minutes: 1)  // 1 min in debug for testing
            : const Duration(hours: 1),   // 1 hour in production
      ));

      // Set default values
      await _remoteConfig!.setDefaults({
        'ads_enabled': true,  // Default: ads are enabled
        'ads_banner_enabled': true,
        'ads_interstitial_enabled': true,
        'ads_interstitial_frequency': 5,  // Show every 5 location switches
        'ads_web_enabled': true,  // Default: web ads are enabled (requires ads_enabled)
      });

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
      
      _initialized = true;
      debugPrint('✅ Remote Config initialized successfully');
      debugPrint('📊 ads_enabled: ${_remoteConfig!.getBool('ads_enabled')}');
    } catch (e) {
      debugPrint('❌ Error initializing Remote Config: $e');
      // Don't rethrow - app should work even if Remote Config fails
      _initialized = false;
    }
  }

  /// Get whether ads are enabled (feature flag)
  bool get adsEnabled {
    if (!_initialized || _remoteConfig == null) {
      debugPrint('⚠️ Remote Config not initialized, using default: true');
      return true; // Default to enabled if Remote Config fails
    }
    return _remoteConfig!.getBool('ads_enabled');
  }

  /// Get whether banner ads are enabled
  bool get bannerAdsEnabled {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool('ads_banner_enabled');
  }

  /// Get whether interstitial ads are enabled
  bool get interstitialAdsEnabled {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool('ads_interstitial_enabled');
  }

  /// Get interstitial ad frequency (show every N location switches)
  int get interstitialFrequency {
    if (!_initialized || _remoteConfig == null) return 5;
    return _remoteConfig!.getInt('ads_interstitial_frequency');
  }

  /// Get whether web ads are enabled (locked behind master ads_enabled flag)
  bool get webAdsEnabled {
    if (!_initialized || _remoteConfig == null) return true;
    return _remoteConfig!.getBool('ads_web_enabled');
  }

  /// Manually fetch latest config (useful for testing)
  Future<void> fetchConfig() async {
    if (!_initialized || _remoteConfig == null) {
      debugPrint('⚠️ Remote Config not initialized');
      return;
    }

    try {
      debugPrint('🔄 Fetching Remote Config...');
      await _remoteConfig!.fetchAndActivate();
      debugPrint('✅ Remote Config fetched');
      debugPrint('📊 ads_enabled: ${_remoteConfig!.getBool('ads_enabled')}');
    } catch (e) {
      debugPrint('❌ Error fetching Remote Config: $e');
    }
  }
}
