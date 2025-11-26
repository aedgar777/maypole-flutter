import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../domain/domain_user.dart';
import './widgets/auth_form_field.dart';
import '../auth_providers.dart';
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

  Widget _buildLoggedInView(DomainUser user, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Automatically navigate to home list when user is registered and logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/home');
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.welcome(user.email)),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.continueToApp),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(RegistrationState registrationState,
      BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  labelText: l10n.username,
                  onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                      _handleRegistration() : null,
                  validator: StringUtils.validateUsername
              ),
              const SizedBox(height: 20),
              AuthFormField(
                  controller: _emailController,
                  labelText: l10n.email,
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                      _handleRegistration() : null,
                  validator: StringUtils.validateEmail
              ),
              const SizedBox(height: 20),
              AuthFormField(
                  controller: _passwordController,
                  labelText: l10n.password,
                  obscureText: true,
                  onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                      _handleRegistration() : null,
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
                      child: Text(l10n.register),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(l10n.alreadyHaveAccount),
                    ),
                  ],
                ),
              if (registrationState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    registrationState.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.register),
      ),
      body: ref.watch(authStateProvider).when(
        data: (user) =>
        user != null
            ? _buildLoggedInView(user, context)
            : _buildRegistrationForm(registrationState, context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
      ),
    );
  }
}
