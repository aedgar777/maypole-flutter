import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maypole/core/utils/string_utils.dart';
import './widgets/auth_form_field.dart';
import './providers/auth_providers.dart';
import '../domain/states/auth_state.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildLoggedInView(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome ${user.email}'),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Continue to App'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(RegistrationState registrationState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthFormField(
                controller: _usernameController,
                labelText: 'Username',
                validator: StringUtils.validateUsername
              ),
              const SizedBox(height: 20),
              AuthFormField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: StringUtils.validateEmail
              ),
              const SizedBox(height: 20),
              AuthFormField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: StringUtils.validatePassword
              ),
              const SizedBox(height: 30),
              if (registrationState.isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _handleRegistration,
                      child: const Text('Register'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              if (registrationState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    registrationState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      ref.read(registrationViewModelProvider.notifier).register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: ref.watch(authStateProvider).when(
        data: (user) => user != null
            ? _buildLoggedInView(user)
            : _buildRegistrationForm(registrationState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}