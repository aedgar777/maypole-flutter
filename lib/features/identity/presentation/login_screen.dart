import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../domain/states/auth_state.dart';
import '../auth_providers.dart';
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

  void _navigateToHome(BuildContext context) {
    // Automatically navigate to home when user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(loginViewModelProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  Widget _buildLoginForm(AuthState loginState, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    labelText: l10n.email,
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                        _handleSignIn() : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterEmail;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return l10n.pleaseEnterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AuthFormField(
                    controller: _passwordController,
                    labelText: l10n.password,
                    obscureText: true,
                    onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                        _handleSignIn() : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterPassword;
                      }
                      if (value.length < 6) {
                        return l10n.passwordMinLength;
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
                          child: Text(l10n.signIn, style: const TextStyle(
                              fontSize: 18)),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(l10n.register),
                        ),
                        if (loginState.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              loginState.errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ref.watch(authStateProvider).when(
        data: (user) {
          if (user != null) {
            _navigateToHome(context);
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              _buildLoginForm(loginState, context),
              if (!AppConfig.isProduction)
                Positioned(
                  bottom: 20,
                  left: 16,
                  child: Text(
                    l10n.devEnvironment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorDialog.show(context, err);
          });
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
