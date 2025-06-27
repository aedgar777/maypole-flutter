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

  Future<void> validateUsername(String username) async {
    if (username.isEmpty) {
      state = state.copyWith(isUsernameValid: false, errorMessage: 'Username cannot be empty');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final isAvailable = await _authService.isUsernameAvailable(username);
      state = state.copyWith(
        isLoading: false,
        isUsernameValid: isAvailable,
        errorMessage: isAvailable ? null : 'Username is already taken',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isUsernameValid: false,
        errorMessage: 'Error checking username',
      );
    }
  }
}