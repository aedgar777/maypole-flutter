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
/// Uses asyncMap with a small delay to ensure Firebase is fully initialized
/// before accessing FirebaseAuth.instance on web
final betaAccessProvider = StreamProvider<BetaAccessResult>((ref) {
  final service = ref.watch(betaAccessServiceProvider);
  
  // Add a small delay on first initialization to ensure Firebase Auth
  // completes its async persistence setup on web platforms
  // This prevents the "assert.ts" error from Firebase Auth initialization
  return Stream.fromFuture(
    Future.delayed(const Duration(milliseconds: 100))
  ).asyncExpand((_) => service.watchBetaAccess());
});
