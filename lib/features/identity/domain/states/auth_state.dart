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
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
    bool clearError = false,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUsernameValid: isUsernameValid ?? this.isUsernameValid,
    );
  }
}

/// State for the username step a first-time Google user has to clear.
class GoogleUsernameState extends AuthState {
  /// True once the profile has been written and the user can be sent onward.
  final bool isComplete;

  const GoogleUsernameState({
    super.isLoading,
    super.errorMessage,
    this.isComplete = false,
  });

  GoogleUsernameState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isComplete,
    bool clearError = false,
  }) {
    return GoogleUsernameState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
