import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/identity/domain/blocked_user.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _confirmUnblock(BuildContext context,
      WidgetRef ref,
      BlockedUser blockedUser,) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(l10n.unblockUser),
            content: Text(l10n.unblockUserConfirmation(blockedUser.username)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.unblock),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Get the current user
      final currentUser = await ref.read(authStateProvider.future);
      if (currentUser == null) return;

      // Remove from blocked users list
      currentUser.blockedUsers.removeWhere(
            (user) => user.firebaseId == blockedUser.firebaseId,
      );

      // Update in Firebase
      await ref.read(authServiceProvider).updateUserData(currentUser);

      if (context.mounted) {
        AppToast.showSuccess(context, l10n.userUnblocked(blockedUser.username));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDialog.show(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blockedUsers),
        leading: AppConfig.isWideScreen ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (user.blockedUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  l10n.noBlockedUsers,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: user.blockedUsers.length,
            itemBuilder: (context, index) {
              final blockedUser = user.blockedUsers[index];
              return Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(blockedUser.username),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _confirmUnblock(
                            context,
                            ref,
                            blockedUser,
                          ),
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorDialog.show(context, error);
          });
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
