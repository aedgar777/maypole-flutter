import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth_providers.dart';
import '../../data/services/auth_service.dart';
import '../../domain/states/auth_state.dart';

class RegistrationViewModel extends Notifier<RegistrationState> {
  late final AuthService _authService;

  @override
  RegistrationState build() {
    _authService = ref.watch(authServiceProvider);
    return const RegistrationState();
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    // Clear any previous errors and set loading state
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Username availability check is done in registerWithEmailAndPassword
      await _authService.registerWithEmailAndPassword(
        email,
        password,
        username,
      );
      state = state.copyWith(isLoading: false, clearError: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _messageFor(e));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Turns a Firebase error code into something worth showing a person.
  ///
  /// Previously every failure surfaced as `e.toString()`, which renders as
  /// "[firebase_auth/email-already-in-use] ..." — the raw code and all. The
  /// email case matters more now than it used to: with account linking enabled
  /// a Google user can reach this screen and try to register the address they
  /// already sign in with, and the answer is to sign in rather than to keep
  /// editing the form.
  ///
  /// Deliberately does not say *which* method the existing account uses. The
  /// error already reveals that the address is taken, but naming the provider
  /// would disclose more than that about someone else's account.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'username-taken':
        return 'That username is already taken.';
      case 'email-already-in-use':
        return 'An account already exists for this email address. Try signing '
            'in instead.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Registration is currently unavailable. Please try again later.';
      case 'network-request-failed':
        return 'No connection. Check your network and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

