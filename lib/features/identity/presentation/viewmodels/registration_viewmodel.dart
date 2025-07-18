import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth_service.dart';
import '../../domain/states/auth_state.dart';


class RegistrationViewModel extends StateNotifier<RegistrationState> {
  final AuthService _authService;

  RegistrationViewModel({required AuthService authService})
      : _authService = authService,
        super(const RegistrationState());

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