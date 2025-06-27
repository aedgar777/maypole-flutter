import 'package:flutter/foundation.dart';

@immutable
abstract class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
  });
}

class LoginState extends AuthState {
  const LoginState({
    super.isLoading,
    super.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RegistrationState extends AuthState {
  final bool isUsernameValid;

  const RegistrationState({
    super.isLoading,
    super.errorMessage,
    this.isUsernameValid = false,
  });

  RegistrationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isUsernameValid,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isUsernameValid: isUsernameValid ?? this.isUsernameValid,
    );
  }
}