import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'presentation/login_viewmodel.dart';

// AuthService provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final loginViewModelProvider = StateNotifierProvider<LoginViewModel, LoginState>(
      (ref) => LoginViewModel(authService: ref.read(authServiceProvider)),
);

final authStateChangesProvider = StreamProvider<User?>(
      (ref) => ref.read(authServiceProvider).user,
);