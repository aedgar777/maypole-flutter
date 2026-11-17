import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import './widgets/auth_form_field.dart';
import './widgets/google_sign_in_button.dart';
import '../auth_providers.dart';
import '../domain/states/auth_state.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String? returnTo;

  const RegistrationScreen({super.key, this.returnTo});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _hasShownSuccessDialog = false;
  bool _ageConfirmed = false;
  bool _privacyPolicyAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showSuccessDialogAndNavigate(BuildContext context) {
    // Prevent showing dialog multiple times
    if (_hasShownSuccessDialog) return;
    _hasShownSuccessDialog = true;

    // Show success dialog informing user about verification email
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final email = _emailController.text.trim();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.registrationSuccessTitle)),
            ],
          ),
          content: Text(
            l10n.registrationSuccessMessage(email),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (mounted) {
                  context.go('/home');
                }
              },
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRegistrationForm(
    RegistrationState registrationState,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppConfig.isWideScreen
                  ? MediaQuery.of(context).size.width / 3
                  : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthFormField(
                    controller: _usernameController,
                    labelText: l10n.username,
                    maxLength: StringUtils.maxUsernameLength,
                    onFieldSubmitted: AppConfig.isWideScreen
                        ? (_) => _handleRegistration()
                        : null,
                    validator: (value) =>
                        StringUtils.validateUsername(value, l10n),
                  ),
                  const SizedBox(height: 20),
                  AuthFormField(
                    controller: _emailController,
                    labelText: l10n.email,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: StringUtils.maxEmailLength,
                    onFieldSubmitted: AppConfig.isWideScreen
                        ? (_) => _handleRegistration()
                        : null,
                    validator: (value) =>
                        StringUtils.validateEmail(value, l10n),
                  ),
                  const SizedBox(height: 20),
                  AuthFormField(
                    controller: _passwordController,
                    labelText: l10n.password,
                    obscureText: true,
                    maxLength: StringUtils.maxPasswordLength,
                    onFieldSubmitted: AppConfig.isWideScreen
                        ? (_) => _handleRegistration()
                        : null,
                    validator: (value) =>
                        StringUtils.validatePassword(value, l10n),
                  ),
                  const SizedBox(height: 20),
                  AuthFormField(
                    controller: _confirmPasswordController,
                    labelText: l10n.confirmPassword,
                    obscureText: true,
                    maxLength: StringUtils.maxPasswordLength,
                    onFieldSubmitted: AppConfig.isWideScreen
                        ? (_) => _handleRegistration()
                        : null,
                    validator: (value) => StringUtils.validateConfirmPassword(
                      value,
                      _passwordController.text,
                      l10n,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Age confirmation checkbox
                  CheckboxListTile(
                    value: _ageConfirmed,
                    onChanged: (value) {
                      setState(() {
                        _ageConfirmed = value ?? false;
                      });
                    },
                    title: const Text(
                      'I confirm that I am 13 years of age or older',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  // Privacy Policy acceptance checkbox with link
                  CheckboxListTile(
                    value: _privacyPolicyAccepted,
                    onChanged: (value) {
                      setState(() {
                        _privacyPolicyAccepted = value ?? false;
                      });
                    },
                    title: RichText(
                      text: TextSpan(
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.push('/privacy-policy');
                              },
                          ),
                        ],
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  const SizedBox(height: 20),

                  if (registrationState.isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: (_ageConfirmed && _privacyPolicyAccepted)
                              ? _handleRegistration
                              : null,
                          child: Text(l10n.register),
                        ),

                        // Below the form, matching the login screen: the
                        // third-party route is an alternative to filling this
                        // in, not the headline action.
                        const SizedBox(height: 16),
                        const AuthDivider(),
                        const SizedBox(height: 16),
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isLoading: ref.watch(loginViewModelProvider).isLoading,
                        ),
                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () => context.go(
                            Uri(
                              path: '/login',
                              queryParameters: widget.returnTo == null
                                  ? null
                                  : {'returnTo': widget.returnTo},
                            ).toString(),
                          ),
                          child: Text(l10n.alreadyHaveAccount),
                        ),
                      ],
                    ),
                  if (registrationState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        registrationState.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Same flow as the login screen's Google button. Offered here too because
  /// "register" is where someone creating an account naturally goes, and making
  /// them back out to login to find it would be a pointless detour.
  Future<void> _handleGoogleSignIn() async {
    final needsUsername =
        await ref.read(loginViewModelProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (needsUsername) {
      context.go(
        Uri(
          path: '/complete-profile',
          queryParameters:
              widget.returnTo == null ? null : {'returnTo': widget.returnTo},
        ).toString(),
      );
      return;
    }

    // Not a new account after all — they already had one, and the Google
    // credential just signed them into it. Surface any failure; a success needs
    // no action, as the auth stream routes them onward.
    final error = ref.read(loginViewModelProvider).errorMessage;
    if (error != null) {
      AppToast.showError(context, error);
    }
  }

  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(registrationViewModelProvider.notifier)
          .register(
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
      appBar: AppBar(title: Text(l10n.register)),
      body: ref
          .watch(authStateProvider)
          .when(
            data: (user) {
              // A non-null user alongside an error means the Firebase account
              // was created but a later step (display name, Firestore write,
              // username reservation) threw. `errorMessage` only renders
              // inside the form, so falling through to the spinner here would
              // strand the user on it with the failure invisible.
              if (user != null && registrationState.errorMessage == null) {
                _showSuccessDialogAndNavigate(context);
                return const Center(child: CircularProgressIndicator());
              }
              return _buildRegistrationForm(registrationState, context);
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
