import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth_providers.dart';
import '../../data/services/auth_service.dart';
import '../../domain/states/auth_state.dart';

/// Drives the username step of a first-time Google sign-up.
///
/// Deliberately narrow: the account already exists in Firebase Auth by the time
/// this runs, so the only outcomes are "profile written" or "pick a different
/// name". The one other thing it owns is [abandon], because walking away from
/// this screen is a real outcome that has to clean up after itself rather than
/// leaving a Firebase account with no profile behind it.
class GoogleUsernameViewModel extends Notifier<GoogleUsernameState> {
  late final AuthService _authService;

  @override
  GoogleUsernameState build() {
    _authService = ref.watch(authServiceProvider);
    return const GoogleUsernameState();
  }

  /// Claims [username] and writes the profile, completing the sign-up.
  Future<void> submit(String username) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.completeGoogleProfile(username.trim());
      ref.read(googleProfileSetupProvider.notifier).clear();
      state = state.copyWith(isLoading: false, isComplete: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFor(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Unwinds the sign-up when the user leaves without choosing a name.
  ///
  /// Always clears the pending state, even if the clean-up throws — leaving it
  /// set would pin the user to this screen with no way out.
  Future<void> abandon() async {
    try {
      await _authService.abandonGoogleProfileSetup();
    } finally {
      ref.read(googleProfileSetupProvider.notifier).clear();
      state = const GoogleUsernameState();
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'username-taken':
        return 'That username is already taken.';
      case 'no-current-user':
        return 'Your Google sign-in session expired. Please sign in again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
