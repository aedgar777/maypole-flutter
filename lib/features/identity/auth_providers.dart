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