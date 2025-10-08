import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth_service.dart';
import '../../domain/states/auth_state.dart';




class LoginViewModel extends StateNotifier<LoginState> {
  final AuthService _authService;

  LoginViewModel({required AuthService authService})
      : _authService = authService,
        super(const LoginState()); // Initialize the state

  // Methods to update state
  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setErrorMessage(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _setErrorMessage(null); // Clear previous errors
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // Success: No need to set message, state will reflect user login
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }
      _setErrorMessage(message);
    } catch (e) {
      _setErrorMessage('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _authService.signOut();
    } catch (e) {
      _setErrorMessage('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }
}