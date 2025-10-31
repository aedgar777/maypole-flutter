import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/states/auth_state.dart';
import 'presentation/viewmodels/login_viewmodel.dart';
import 'presentation/viewmodels/registration_viewmodel.dart';
import 'data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final loginViewModelProvider = StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginViewModel(authService: authService);
});

final registrationViewModelProvider = StateNotifierProvider<RegistrationViewModel, RegistrationState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return RegistrationViewModel(authService: authService);
});

final authStateProvider = StreamProvider((ref) {
  return ref.read(authServiceProvider).user;
});