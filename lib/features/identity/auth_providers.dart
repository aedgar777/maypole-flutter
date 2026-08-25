import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/states/auth_state.dart';
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
