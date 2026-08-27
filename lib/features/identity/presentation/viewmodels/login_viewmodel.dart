import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth_providers.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/google_sign_in_service.dart';
import '../../domain/google_sign_in_result.dart';
import '../../domain/states/auth_state.dart';

class LoginViewModel extends Notifier<LoginState> {
  late final AuthService _authService;

  @override
  LoginState build() {
    _authService = ref.watch(authServiceProvider);
    return const LoginState();
  }

  // Methods to update state
  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setErrorMessage(String? message) {
    state = state.copyWith(errorMessage: message);
  }
  
  void _clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError(); // Clear previous errors
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // Success: No need to set message, state will reflect user login
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }
      _setErrorMessage(message);
    } catch (e) {
      _setErrorMessage('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Runs the Google flow.
  ///
  /// Returns true when the user still has to pick a username, so the caller can
  /// route them to `/complete-profile`. Returning false covers both a completed
  /// sign-in and a cancelled one — in neither case is there anywhere to go, and
  /// the auth stream drives navigation for the former.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.signInWithGoogle();

      if (result.outcome == GoogleSignInOutcome.needsUsername) {
        ref.read(googleProfileSetupProvider.notifier).start(result);
        return true;
      }
      return false;
    } on GoogleSignInCancelled {
      // Backing out of the account picker is not an error worth reporting.
      return false;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          // The project has "Link accounts that use the same email" enabled,
          // so Google — which always verifies the address — is linked to any
          // existing account automatically and this does not fire for it. It
          // survives for the case that setting does not cover: a provider that
          // hands back an unverified email, which Firebase refuses to link
          // because doing so would let an unverified address take over an
          // account. Telling the user to "use your password instead" would be
          // wrong, since the obstacle is the provider, not the method.
          message =
              'This email is already registered and could not be linked '
              'automatically. Sign in using the method you signed up with.';
          break;
        case 'invalid-credential':
          message = 'Google sign-in could not be completed. Please try again.';
          break;
        case 'operation-not-allowed':
          message = 'Google sign-in is not enabled for this app.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          message = 'No connection. Check your network and try again.';
          break;
        default:
          message = 'Google sign-in failed: ${e.message}';
      }
      _setErrorMessage(message);
      return false;
    } catch (e) {
      _setErrorMessage('An unexpected error occurred: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signOut();
    } catch (e) {
      _setErrorMessage('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }
}
