import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});