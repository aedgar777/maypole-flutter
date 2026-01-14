import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

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

    try {
      // Show loading indicator
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
        const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete the account
      await ref.read(authServiceProvider).deleteAccount();

      // Close loading indicator
      if (!context.mounted) return;
      Navigator.pop(context);

      // Show success message
      if (!context.mounted) return;
      AppToast.showSuccess(context, l10n.accountDeleted);

      // Navigate to login screen
      if (!context.mounted) return;
      context.go('/login');
    } catch (e) {
      // Close loading indicator if open
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (!context.mounted) return;
      ErrorDialog.show(context, e);
    }
  }

  Future<void> _handleResendVerification(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(authServiceProvider).sendEmailVerification();

      if (!context.mounted) return;
      AppToast.showSuccess(context, l10n.verificationEmailSent);
    } catch (e) {
      if (!context.mounted) return;
      ErrorDialog.show(context, e);
    }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettings),
        leading: AppConfig.isWideScreen ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return Column(
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(l10n.emailAddress),
                subtitle: Text(user.email),
                trailing: _buildEmailVerificationStatus(
                    context, user.emailVerified),
                onTap: user.emailVerified
                    ? null
                    : () => _handleResendVerification(context, ref),
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
    );
  }
}
