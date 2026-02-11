import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
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
      debugPrint('🚀 Initializing AdMob SDK on ${Platform.isIOS ? 'iOS' : 'Android'}...');
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

  /// Verify that ads.txt is accessible and correctly configured
  /// 
  /// This calls a Cloud Function that checks the ads.txt file on the domain
  /// to ensure it's properly set up for AdSense verification.
  /// 
  /// Returns a [AdsTxtVerificationResult] with verification status and details
  Future<AdsTxtVerificationResult> verifyAdsTxt({
    String domain = 'https://maypole.app',
  }) async {
    try {
      debugPrint('🔍 Verifying ads.txt configuration...');
      
      final functionUrl = 'https://us-central1-maypole-flutter-ce6c3.cloudfunctions.net/verifyAdsTxt';
      final uri = Uri.parse(functionUrl).replace(queryParameters: {'domain': domain});
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Verification request timed out'),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = AdsTxtVerificationResult.fromJson(json);
        
        if (result.accessible) {
          debugPrint('✅ ads.txt verified successfully');
        } else {
          debugPrint('⚠️ ads.txt verification failed: ${result.error ?? "Unknown error"}');
        }
        
        return result;
      } else {
        throw Exception('Verification request failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error verifying ads.txt: $e');
      return AdsTxtVerificationResult(
        accessible: false,
        error: e.toString(),
        url: '$domain/ads.txt',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
}

/// Result of ads.txt verification check
class AdsTxtVerificationResult {
  final bool accessible;
  final int? status;
  final String? content;
  final String? error;
  final String url;
  final String timestamp;
  final AdsTxtChecks? checks;

  AdsTxtVerificationResult({
    required this.accessible,
    this.status,
    this.content,
    this.error,
    required this.url,
    required this.timestamp,
    this.checks,
  });

  factory AdsTxtVerificationResult.fromJson(Map<String, dynamic> json) {
    return AdsTxtVerificationResult(
      accessible: json['accessible'] as bool,
      status: json['status'] as int?,
      content: json['content'] as String?,
      error: json['error'] as String?,
      url: json['url'] as String,
      timestamp: json['timestamp'] as String,
      checks: json['checks'] != null 
        ? AdsTxtChecks.fromJson(json['checks'] as Map<String, dynamic>)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessible': accessible,
      'status': status,
      'content': content,
      'error': error,
      'url': url,
      'timestamp': timestamp,
      'checks': checks?.toJson(),
    };
  }
}

/// Detailed checks performed during ads.txt verification
class AdsTxtChecks {
  final bool statusOk;
  final bool containsGoogle;
  final bool hasPublisherId;
  final String expectedPublisherId;

  AdsTxtChecks({
    required this.statusOk,
    required this.containsGoogle,
    required this.hasPublisherId,
    required this.expectedPublisherId,
  });

  factory AdsTxtChecks.fromJson(Map<String, dynamic> json) {
    return AdsTxtChecks(
      statusOk: json['statusOk'] as bool,
      containsGoogle: json['containsGoogle'] as bool,
      hasPublisherId: json['hasPublisherId'] as bool,
      expectedPublisherId: json['expectedPublisherId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusOk': statusOk,
      'containsGoogle': containsGoogle,
      'hasPublisherId': hasPublisherId,
      'expectedPublisherId': expectedPublisherId,
    };
  }
}
