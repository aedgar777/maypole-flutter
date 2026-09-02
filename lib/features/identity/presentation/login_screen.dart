import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../domain/states/auth_state.dart';
import '../auth_providers.dart';
import './widgets/auth_form_field.dart';
import './widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? returnTo;

  /// True when the user has just completed a password reset on the web action
  /// handler and was routed back here. Shows a confirmation toast.
  final bool passwordResetSuccess;

  const LoginScreen({
    super.key,
    this.returnTo,
    this.passwordResetSuccess = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Set while a reset confirmation is queued, so the two entry points below
  /// can't both fire for the same arrival.
  bool _showingPasswordResetToast = false;

  @override
  void initState() {
    super.initState();
    // On web the route carries the result and the screen is built fresh, so the
    // widget flag is the signal. On mobile the handoff arrives through
    // [passwordResetSignalProvider] — read it here too, since the router may
    // have set it before this screen's first build registered the listener.
    final arrived = kIsWeb
        ? widget.passwordResetSuccess
        : ref.read(passwordResetSignalProvider) > 0;
    if (arrived) _showPasswordResetToast();
  }

  /// Shows the reset confirmation and clears the signal, so a later rebuild
  /// can't replay it.
  void _showPasswordResetToast() {
    if (_showingPasswordResetToast) return;
    _showingPasswordResetToast = true;

    Future.microtask(() {
      if (!mounted) return;
      if (ref.read(passwordResetSignalProvider) > 0) {
        ref.read(passwordResetSignalProvider.notifier).clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showingPasswordResetToast = false;
      AppToast.showSuccess(
        context,
        AppLocalizations.of(context)!.passwordResetSuccess,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _postAuthRoute {
    final returnTo = widget.returnTo;
    if (returnTo == null || returnTo.isEmpty) {
      return '/home';
    }

    final uri = Uri.tryParse(returnTo);
    if (uri == null || uri.hasScheme || uri.hasAuthority) {
      return '/home';
    }

    return returnTo.startsWith('/') ? returnTo : '/$returnTo';
  }

  void _navigateAfterAuth(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(_postAuthRoute);
      }
    });
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(loginViewModelProvider.notifier)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  /// Runs the Google flow and, for a first-time account, hands off to the
  /// username step. A completed sign-in needs no navigation here — the auth
  /// stream drives it, same as an email sign-in.
  Future<void> _handleGoogleSignIn() async {
    final needsUsername = await ref
        .read(loginViewModelProvider.notifier)
        .signInWithGoogle();

    if (!mounted || !needsUsername) return;

    context.go(
      Uri(
        path: '/complete-profile',
        queryParameters: widget.returnTo == null
            ? null
            : {'returnTo': widget.returnTo},
      ).toString(),
    );
  }

  Future<void> _handleForgotPassword() async {
    final result = await showDialog<_ForgotPasswordResult>(
      context: context,
      builder: (_) =>
          _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );

    if (!mounted || result == null) return;
    final l10n = AppLocalizations.of(context)!;
    if (result.success) {
      AppToast.showSuccess(context, l10n.passwordResetEmailSent);
    } else if (result.errorMessage != null) {
      AppToast.showError(context, result.errorMessage!);
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
            final Uri appStoreUrl = Uri.parse(
              'https://apps.apple.com/us/app/maypole/id6757092758',
            );
            if (await canLaunchUrl(appStoreUrl)) {
              await launchUrl(
                appStoreUrl,
                mode: LaunchMode.externalApplication,
              );
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
            final Uri playStoreUrl = Uri.parse(
              'https://play.google.com/store/apps/details?id=app.maypole.maypole',
            );
            if (await canLaunchUrl(playStoreUrl)) {
              await launchUrl(
                playStoreUrl,
                mode: LaunchMode.externalApplication,
              );
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

    // Logo and form share one scroll view rather than sitting in separate
    // boxes. Previously the form had its own Expanded/SingleChildScrollView
    // below a fixed-height logo, so on shorter screens the first element of
    // the form was clipped at the top of its own viewport with no way to
    // reveal it — scrolling the form moved it further away, not closer.
    return Column(
      children: [
        Expanded(
          // Centre the content in whatever space is left, but keep it
          // scrollable: forcing the scroll view's child to be at least as tall
          // as the viewport lets Center do its job when everything fits, while
          // taller content (a small screen, or the keyboard open) simply grows
          // past it and scrolls instead of being clipped or overflowing.
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // The scroll view's own vertical padding is inside the
                  // viewport, so leave room for it or the content is always
                  // fractionally too tall and scrolls by a few pixels.
                  minHeight: viewport.maxHeight - 48,
                ),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The asset is square but the wordmark inside it is
                          // roughly 3:1, so a 300-square box padded it with a large
                          // band of empty space above the form. Constrain the
                          // height instead and let BoxFit.contain size to width.
                          Image.asset(
                            'assets/icons/ic_logo_main.png',
                            width: 300,
                            height: 170,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),

                          // Email and password lead. A third-party button above the
                          // primary form reads as the main path, which it is not.
                          AuthFormField(
                            controller: _emailController,
                            labelText: l10n.email,
                            keyboardType: TextInputType.emailAddress,
                            maxLength: StringUtils.maxEmailLength,
                            onFieldSubmitted: AppConfig.isWideScreen
                                ? (_) => _handleSignIn()
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
                                ? (_) => _handleSignIn()
                                : null,
                            validator: (value) =>
                                StringUtils.validatePassword(value, l10n),
                          ),
                          const SizedBox(height: 24),

                          if (loginState.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(),
                            )
                          else ...[
                            ElevatedButton(
                              onPressed: _handleSignIn,
                              child: Text(
                                l10n.signIn,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            // Grouped with the other email actions rather than after the
                            // Google button. Compact density on both so they read as one
                            // pair: at the default, each button's 48dp minimum tap target
                            // leaves a gap wide enough that they look unrelated.
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => context.go(
                                Uri(
                                  path: '/register',
                                  queryParameters: widget.returnTo == null
                                      ? null
                                      : {'returnTo': widget.returnTo},
                                ).toString(),
                              ),
                              child: Text(l10n.register),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _handleForgotPassword,
                              child: Text(l10n.forgotPassword),
                            ),

                            const SizedBox(height: 12),
                            const AuthDivider(),
                            const SizedBox(height: 16),

                            GoogleSignInButton(
                              onPressed: _handleGoogleSignIn,
                              isLoading: loginState.isLoading,
                            ),
                          ],

                          if (loginState.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                loginState.errorMessage!,
                                textAlign: TextAlign.center,
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
    // Fires when the router records a password-reset handoff while this screen
    // is already on top — the common case, and the one the route cannot report.
    ref.listen<int>(passwordResetSignalProvider, (previous, next) {
      if (next > 0) _showPasswordResetToast();
    });

    final loginState = ref.watch(loginViewModelProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ref
          .watch(authStateProvider)
          .when(
            data: (user) {
              if (user != null) {
                _navigateAfterAuth(context);
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

/// Result returned from the forgot-password dialog. The dialog handles its
/// own lifecycle (controller, form key, sending state) and only reports the
/// outcome so the parent screen can show a toast on its own context.
class _ForgotPasswordResult {
  final bool success;
  final String? errorMessage;
  const _ForgotPasswordResult({required this.success, this.errorMessage});
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_isSending) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      Navigator.of(context).pop(const _ForgotPasswordResult(success: true));
    } on FirebaseAuthException catch (e) {
      // Treat "user-not-found" as success to avoid leaking account existence.
      if (e.code == 'user-not-found') {
        if (!mounted) return;
        Navigator.of(context).pop(const _ForgotPasswordResult(success: true));
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        _ForgotPasswordResult(
          success: false,
          errorMessage: e.code == 'invalid-email'
              ? l10n.pleaseEnterValidEmail
              : (e.message ?? l10n.somethingWentWrong),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(
        _ForgotPasswordResult(
          success: false,
          errorMessage: l10n.somethingWentWrong,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.resetPasswordTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.resetPasswordDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            AuthFormField(
              controller: _emailController,
              labelText: l10n.email,
              keyboardType: TextInputType.emailAddress,
              maxLength: StringUtils.maxEmailLength,
              onFieldSubmitted: (_) => _sendReset(),
              validator: (value) => StringUtils.validateEmail(value, l10n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendReset,
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.sendResetLink),
        ),
      ],
    );
  }
}
