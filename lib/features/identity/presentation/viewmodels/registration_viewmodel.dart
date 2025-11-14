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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {

      final isAvailable = await _authService.isUsernameAvailable(username);
      if (!isAvailable) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Username is already taken',
        );
        return;
      }

      // Proceed with registration if username is available
      await _authService.registerWithEmailAndPassword(
        email,
        password,
        username,
      );
      state = state.copyWith(isLoading: false);
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