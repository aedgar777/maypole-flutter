import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_config_service.dart';

/// Provider for Remote Config service
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

/// Provider for ads enabled state from Remote Config
final adsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.adsEnabled;
});

/// Provider for banner ads enabled state
final bannerAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.bannerAdsEnabled;
});

/// Provider for interstitial ads enabled state
final interstitialAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.interstitialAdsEnabled;
});

/// Provider for interstitial ad frequency
final interstitialFrequencyProvider = Provider<int>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.interstitialFrequency;
});
