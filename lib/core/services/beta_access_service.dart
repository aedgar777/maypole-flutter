import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to check if a user has beta access to the web app
/// Only enforced when ENVIRONMENT=beta on web platform
class BetaAccessService {
  // Use lazy getters to avoid accessing Firebase instances during construction
  // This is critical for web where Firebase Auth needs async initialization
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Check if the current environment requires beta access
  bool get isBetaEnvironment {
    return kIsWeb && const String.fromEnvironment('ENVIRONMENT') == 'beta';
  }

  /// Check if the current user has beta access
  /// Returns true if:
  /// - Not in beta environment (no check needed)
  /// - User is authenticated and has betaTester: true in Firestore
  Future<BetaAccessResult> checkBetaAccess() async {
    // If not in beta environment, allow access
    if (!isBetaEnvironment) {
      return BetaAccessResult(
        hasAccess: true,
        reason: 'Not in beta environment',
      );
    }

    // Check if user is authenticated
    final user = _auth.currentUser;
    if (user == null) {
      return BetaAccessResult(
        hasAccess: false,
        reason: 'User not authenticated',
        requiresAuth: true,
      );
    }

    try {
      // Check if user has beta tester status in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return BetaAccessResult(
          hasAccess: false,
          reason: 'User document not found',
        );
      }

      final data = userDoc.data();
      final isBetaTester = data?['betaTester'] == true;

      if (isBetaTester) {
        return BetaAccessResult(
          hasAccess: true,
          reason: 'User is a beta tester',
        );
      } else {
        return BetaAccessResult(
          hasAccess: false,
          reason: 'User is not enrolled in beta program',
        );
      }
    } catch (e) {
      debugPrint('Error checking beta access: $e');
      return BetaAccessResult(
        hasAccess: false,
        reason: 'Error checking beta access: $e',
      );
    }
  }

  /// Listen to beta access changes for the current user
  Stream<BetaAccessResult> watchBetaAccess() {
    if (!isBetaEnvironment) {
      return Stream.value(BetaAccessResult(
        hasAccess: true,
        reason: 'Not in beta environment',
      ));
    }

    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return BetaAccessResult(
          hasAccess: false,
          reason: 'User not authenticated',
          requiresAuth: true,
        );
      }

      return checkBetaAccess();
    });
  }
}

/// Result of a beta access check
class BetaAccessResult {
  final bool hasAccess;
  final String reason;
  final bool requiresAuth;

  BetaAccessResult({
    required this.hasAccess,
    required this.reason,
    this.requiresAuth = false,
  });

  @override
  String toString() => 'BetaAccessResult(hasAccess: $hasAccess, reason: $reason)';
}
