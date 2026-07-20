import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/utils/screen_utils.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen>
    with WidgetsBindingObserver {
  bool _isResendingEmail = false;
  bool _isDeletingAccount = false;
  DateTime? _lastEmailSentTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh verification status when the screen first opens, in case the
    // user verified their email in an external browser during a previous
    // session and the Firestore mirror flag hasn't caught up yet.
    _refreshEmailVerificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns to the app (e.g. after clicking the verification
    // link in their email/browser), re-check their verification status so the
    // "Verified" badge updates in place without requiring a re-login.
    if (state == AppLifecycleState.resumed) {
      _refreshEmailVerificationStatus();
    }
  }

  /// Reloads the Firebase user and syncs the `emailVerified` flag to Firestore.
  /// If it flips to true, the `authStateProvider` stream emits the updated user
  /// and the badge rebuilds as "Verified" automatically.
  Future<void> _refreshEmailVerificationStatus() async {
    try {
      await ref.read(authServiceProvider).checkEmailVerificationStatus();
    } catch (_) {
      // Non-fatal: the status will refresh on next sign-in.
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context,
      WidgetRef ref,) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .error,
                ),
                const SizedBox(width: 8),
                Text(l10n.deleteAccountTitle),
              ],
            ),
            content: Text(
              l10n.deleteAccountConfirmation,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.delete,
                  style: TextStyle(color: Theme
                      .of(context)
                      .colorScheme
                      .error),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Use an in-widget loading overlay (not a dialog route). Deleting the
    // account clears the auth state, which can navigate this screen away
    // before the delete future completes. An in-widget overlay simply
    // disappears with the screen, so it can never be left stranded on top of
    // the login screen (a full-screen dialog loader would).
    setState(() => _isDeletingAccount = true);

    try {
      await ref.read(authServiceProvider).deleteAccount();

      // On success the auth-state stream emits null and the router redirects to
      // /login; this screen is often already unmounted by now, in which case
      // there is nothing left to do (the app is already back at login).
      if (!context.mounted) return;
      AppToast.showSuccess(context, l10n.accountDeleted);
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isDeletingAccount = false);
      ErrorDialog.show(context, e);
    }
  }

  Future<void> _handleResendVerification(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    // Prevent multiple simultaneous requests
    if (_isResendingEmail) return;

    // Check if we sent an email recently (within last 60 seconds)
    if (_lastEmailSentTime != null) {
      final timeSinceLastEmail = DateTime.now().difference(_lastEmailSentTime!);
      if (timeSinceLastEmail.inSeconds < 60) {
        if (!context.mounted) return;
        final remainingSeconds = 60 - timeSinceLastEmail.inSeconds;
        AppToast.showError(
          context,
          'Please wait $remainingSeconds seconds before requesting another email',
        );
        return;
      }
    }

    setState(() {
      _isResendingEmail = true;
    });

    try {
      // First re-check status: the user may have already verified in an
      // external browser. If so, the stream flips the badge to "Verified" and
      // we skip sending a redundant email.
      final alreadyVerified =
          await ref.read(authServiceProvider).checkEmailVerificationStatus();
      if (alreadyVerified) {
        if (!context.mounted) return;
        AppToast.showSuccess(context, l10n.validated);
        return;
      }

      await ref.read(authServiceProvider).sendEmailVerification();
      
      setState(() {
        _lastEmailSentTime = DateTime.now();
      });

      if (!context.mounted) return;
      AppToast.showSuccess(context, l10n.verificationEmailSent);
    } catch (e) {
      if (!context.mounted) return;
      
      // Check if it's a rate limiting error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('too-many-requests') || 
          errorMessage.contains('too many requests')) {
        AppToast.showError(
          context,
          'Too many verification emails sent. Please check your spam folder or wait a few minutes before trying again.',
        );
      } else {
        ErrorDialog.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  Future<void> _handleChangePassword(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget passwordField({
              required TextEditingController controller,
              required String label,
              required bool obscure,
              required VoidCallback onToggle,
              String? Function(String?)? validator,
              void Function(String)? onSubmitted,
            }) {
              return TextFormField(
                controller: controller,
                obscureText: obscure,
                maxLength: StringUtils.maxPasswordLength,
                onFieldSubmitted: onSubmitted,
                decoration: InputDecoration(
                  labelText: label,
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
                ),
                validator: validator,
              );
            }

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() => isSaving = true);

              try {
                await ref.read(authServiceProvider).changePassword(
                      currentPassword: currentController.text.trim(),
                      newPassword: newController.text.trim(),
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                AppToast.showSuccess(context, l10n.passwordChangedSuccess);
              } on FirebaseAuthException catch (e) {
                setDialogState(() => isSaving = false);
                if (!dialogContext.mounted) return;

                final String message;
                switch (e.code) {
                  case 'wrong-password':
                  case 'invalid-credential':
                    message = l10n.currentPasswordIncorrect;
                    break;
                  case 'weak-password':
                    message = l10n.passwordMinLength;
                    break;
                  case 'requires-recent-login':
                    message = l10n.pleaseSignInAgainToChangePassword;
                    break;
                  default:
                    message = e.message ?? l10n.somethingWentWrong;
                }
                AppToast.showError(dialogContext, message);
              } catch (_) {
                setDialogState(() => isSaving = false);
                if (!dialogContext.mounted) return;
                AppToast.showError(dialogContext, l10n.somethingWentWrong);
              }
            }

            return AlertDialog(
              title: Text(l10n.changePassword),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      passwordField(
                        controller: currentController,
                        label: l10n.currentPassword,
                        obscure: obscureCurrent,
                        onToggle: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? l10n.pleaseEnterPassword
                                : null,
                      ),
                      const SizedBox(height: 12),
                      passwordField(
                        controller: newController,
                        label: l10n.newPassword,
                        obscure: obscureNew,
                        onToggle: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                        validator: (value) {
                          final base =
                              StringUtils.validatePassword(value, l10n);
                          if (base != null) return base;
                          if (value == currentController.text.trim()) {
                            return l10n.newPasswordMustDiffer;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      passwordField(
                        controller: confirmController,
                        label: l10n.confirmNewPassword,
                        obscure: obscureConfirm,
                        onToggle: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                        onSubmitted: (_) => submit(),
                        validator: (value) =>
                            StringUtils.validateConfirmPassword(
                          value,
                          newController.text.trim(),
                          l10n,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.updatePassword),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Widget _buildEmailVerificationStatus(
      BuildContext context, bool isVerified) {
    final l10n = AppLocalizations.of(context)!;
    
    if (isVerified) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.validated,
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_outlined,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.notValidated,
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: Colors.orange,
            size: 16,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettings),
        leading: !AppConfig.isWideScreen && ScreenUtils.shouldShowAppBarBackButton()
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        )
            : null,
        automaticallyImplyLeading: !AppConfig.isWideScreen && ScreenUtils.shouldShowAppBarBackButton()
      ),
      body: Stack(
        children: [
          authState.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return Column(
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(l10n.emailAddress),
                subtitle: Text(user.email),
                trailing: _isResendingEmail
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _buildEmailVerificationStatus(
                        context, user.emailVerified),
                onTap: (user.emailVerified || _isResendingEmail)
                    ? null
                    : () => _handleResendVerification(context, ref),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.changePassword),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _handleChangePassword(context, ref),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(l10n.blockedUsers),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/blocked-users'),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  l10n.deleteAccount,
                  style: const TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
          if (_isDeletingAccount)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
