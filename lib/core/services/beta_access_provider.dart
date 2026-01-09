import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'beta_access_service.dart';

/// Provider for the beta access service
final betaAccessServiceProvider = Provider<BetaAccessService>((ref) {
  return BetaAccessService();
});

/// Provider that checks if beta access is required
final requiresBetaAccessProvider = Provider<bool>((ref) {
  return ref.watch(betaAccessServiceProvider).isBetaEnvironment;
});

/// Provider that watches beta access status
final betaAccessProvider = StreamProvider<BetaAccessResult>((ref) {
  final service = ref.watch(betaAccessServiceProvider);
  return service.watchBetaAccess();
});
