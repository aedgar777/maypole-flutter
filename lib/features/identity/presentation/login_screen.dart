import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  void _openPrivacyPolicy() {
    context.go('/privacy-policy');
  }

  void _openHelp() {
    context.go('/help');
  }

  Future<void> _openFeedback() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'info@maypole.app',
        query: 'body=Describe your issue or suggestions:',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      // Silently fail for login screen
    }
  }

  Widget _buildAppStoreBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Apple App Store Badge
        InkWell(
          onTap: () async {
            final Uri appStoreUrl = Uri.parse('https://apps.apple.com/us/app/maypole/id6757092758');
            if (await canLaunchUrl(appStoreUrl)) {
              await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
            }
          },
          child: SvgPicture.asset(
            'assets/images/badges/app_store_badge.svg',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 16),
        // Google Play Store Badge - wrapped in Container with white background
        // because the SVG has a black background rectangle
        InkWell(
          onTap: () async {
            final Uri playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=app.maypole.maypole');
            if (await canLaunchUrl(playStoreUrl)) {
              await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SvgPicture.asset(
              'assets/images/badges/play_store_badge.svg',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: _openPrivacyPolicy,
          child: Text(
            l10n.privacy,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(width: 16),
        InkWell(
          onTap: _openHelp,
          child: Text(
            l10n.help,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(width: 16),
        InkWell(
          onTap: _openFeedback,
          child: Text(
            l10n.feedback,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
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
                    maxLength: StringUtils.maxEmailLength,
                    onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                        _handleSignIn() : null,
                    validator: (value) => StringUtils.validateEmail(value, l10n),
                  ),
                  const SizedBox(height: 20),
                  AuthFormField(
                    controller: _passwordController,
                    labelText: l10n.password,
                    obscureText: true,
                    maxLength: StringUtils.maxPasswordLength,
                    onFieldSubmitted: AppConfig.isWideScreen ? (_) =>
                        _handleSignIn() : null,
                    validator: (value) => StringUtils.validatePassword(value, l10n),
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
        // Web-only footer with app store badges and links
        if (AppConfig.isWideScreen)
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Column(
              children: [
                _buildAppStoreBadges(),
                const SizedBox(height: 16),
                _buildFooterLinks(context),
              ],
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
