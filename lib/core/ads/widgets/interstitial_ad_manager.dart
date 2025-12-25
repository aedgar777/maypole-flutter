import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_config.dart';
import '../ad_providers.dart';

/// Manager for loading and showing interstitial ads
/// Use this for full-screen ads between content transitions
class InterstitialAdManager {
  final Ref ref;
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  InterstitialAdManager(this.ref);

  /// Load an interstitial ad
  Future<void> loadAd() async {
    if (!AdConfig.adsEnabled || !ref.read(adInitializedProvider)) {
      debugPrint('📵 Interstitial ads are not available');
      return;
    }

    if (_isLoading) {
      debugPrint('⚠️ Interstitial ad is already loading');
      return;
    }

    if (_interstitialAd != null) {
      debugPrint('⚠️ Interstitial ad is already loaded');
      return;
    }

    _isLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ Interstitial ad loaded');
            _interstitialAd = ad;
            _isLoading = false;

            // Set up full screen content callback
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('📱 Interstitial ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('📱 Interstitial ad dismissed');
                ad.dispose();
                _interstitialAd = null;
                // Preload the next ad
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Interstitial ad failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
                _isLoading = false;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Interstitial ad failed to load: $error');
            _isLoading = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading interstitial ad: $e');
      _isLoading = false;
    }
  }

  /// Show the interstitial ad if it's loaded
  /// Returns true if the ad was shown, false otherwise
  Future<bool> showAd() async {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Interstitial ad is not ready');
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('❌ Error showing interstitial ad: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return false;
    }
  }

  /// Check if an ad is ready to be shown
  bool get isAdReady => _interstitialAd != null;

  /// Dispose of the current ad
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

/// Provider for interstitial ad manager
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager(ref);
  
  // Automatically load the first ad
  Future.delayed(Duration.zero, () {
    manager.loadAd();
  });
  
  return manager;
});
