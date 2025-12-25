import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_service.dart';

/// Provider for the AdMob service singleton
final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// Simple notifier for AdMob initialization state
class AdInitializedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setInitialized(bool value) {
    state = value;
  }
}

/// Provider to track if AdMob is initialized
final adInitializedProvider = NotifierProvider<AdInitializedNotifier, bool>(
  AdInitializedNotifier.new,
);
