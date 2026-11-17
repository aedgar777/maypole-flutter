import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/google_sign_in_result.dart';
import 'domain/states/auth_state.dart';
import 'presentation/viewmodels/google_username_viewmodel.dart';
import 'presentation/viewmodels/login_viewmodel.dart';
import 'presentation/viewmodels/registration_viewmodel.dart';
import 'data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);

final registrationViewModelProvider =
    NotifierProvider<RegistrationViewModel, RegistrationState>(
      RegistrationViewModel.new,
    );

final authStateProvider = StreamProvider((ref) {
  return ref.read(authServiceProvider).user;
});

/// One-shot signal that a password reset completed on `auth-action.html` and
/// handed control back to the native app.
///
/// [LoginScreen] cannot learn this from its route: the handoff usually targets
/// the `/login` the user is already on, and go_router treats that as no
/// navigation, so the screen is never rebuilt with the query parameter. The
/// router bumps this counter on arrival and the screen consumes it. A counter
/// rather than a flag so a second reset in the same session fires again.
class PasswordResetSignal extends Notifier<int> {
  @override
  int build() => 0;

  /// Records that a reset handed back to the app.
  void signal() => state = state + 1;

  /// Clears the signal once the confirmation has been shown.
  void clear() => state = 0;
}

final passwordResetSignalProvider =
    NotifierProvider<PasswordResetSignal, int>(PasswordResetSignal.new);


/// Holds the half-finished Google sign-up between authenticating with Google
/// and choosing a Maypole username.
///
/// The router keys off this rather than off the auth stream, because during
/// this window the two disagree on purpose: Firebase has a signed-in user, but
/// [authStateProvider] emits null since no profile document exists yet. Left to
/// itself the router would read that as "signed out" and bounce the user to
/// login, losing the account they just created. A non-null value here means
/// "authenticated, but not finished" and pins them to `/complete-profile`.
class GoogleProfileSetup extends Notifier<GoogleSignInResult?> {
  @override
  GoogleSignInResult? build() => null;

  /// Records that a first-time Google user needs a username.
  void start(GoogleSignInResult result) => state = result;

  /// Clears the pending state once the user has finished — or walked away.
  void clear() => state = null;
}

final googleProfileSetupProvider =
    NotifierProvider<GoogleProfileSetup, GoogleSignInResult?>(
  GoogleProfileSetup.new,
);

final googleUsernameViewModelProvider =
    NotifierProvider<GoogleUsernameViewModel, GoogleUsernameState>(
  GoogleUsernameViewModel.new,
);
