import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Service for managing AdMob SDK initialization and ad loading
class AdService {
  bool _isInitialized = false;

  /// Initialize the Mobile Ads SDK (mobile only)
  Future<void> initialize() async {
    if (!AdConfig.adsEnabled) {
      debugPrint('📵 Ads are disabled');
      return;
    }

    // Only initialize AdMob on mobile platforms (Android/iOS)
    if (kIsWeb) {
      debugPrint('🌐 Skipping AdMob initialization on web (not supported)');
      return;
    }

    if (_isInitialized) {
      debugPrint('⚠️ AdMob already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing AdMob SDK on ${defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android'}...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob SDK initialized successfully');

      // Optional: Set request configuration for testing
      if (AdConfig.useTestAds) {
        debugPrint('🧪 Using test ads');
        // You can add test device IDs here if needed
        // final testDeviceIds = ['YOUR_TEST_DEVICE_ID'];
        // final configuration = RequestConfiguration(testDeviceIds: testDeviceIds);
        // MobileAds.instance.updateRequestConfiguration(configuration);
      }
    } catch (e) {
      debugPrint('❌ Error initializing AdMob: $e');
      rethrow;
    }
  }

  /// Check if ads are enabled and initialized
  bool get isReady => AdConfig.adsEnabled && _isInitialized;

  /// Create a banner ad
  BannerAd createBannerAd({
    required BannerAdListener listener,
    AdSize adSize = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: listener,
    );
  }

  /// Load an interstitial ad
  Future<InterstitialAd?> loadInterstitialAd() async {
    if (!isReady) return null;

    try {
      debugPrint('📱 Loading interstitial ad...');
      InterstitialAd? ad;
      
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd loadedAd) {
            debugPrint('✅ Interstitial ad loaded');
            ad = loadedAd;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('❌ Interstitial ad failed to load: $error');
          },
        ),
      );
      
      return ad;
    } catch (e) {
      debugPrint('❌ Error loading interstitial ad: $e');
      return null;
    }
  }
}
