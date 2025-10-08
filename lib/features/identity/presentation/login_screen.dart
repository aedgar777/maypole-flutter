import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/states/auth_state.dart';
import './providers/auth_providers.dart';
import './widgets/auth_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildLoggedInView(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome ${user.email}'),
          ElevatedButton(
            onPressed: () {
              ref.read(loginViewModelProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(loginViewModelProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  Widget _buildLoginForm(AuthState loginState) {
    return Column(
      children: [
        const Spacer(flex: 1),
        Image.asset(
          'assets/icons/ic_logo_main.png',
          width: 300,
          height: 300,
        ),
        const Spacer(flex: 1),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AuthFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  if (loginState.isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Register'),
                        ),
                        if (loginState.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              loginState.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    return Scaffold(
      body: ref.watch(authStateProvider).when(
        data: (user) => user != null
            ? _buildLoggedInView(user)
            : _buildLoginForm(loginState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}