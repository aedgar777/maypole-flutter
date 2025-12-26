import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/core/widgets/lazy_profile_avatar.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/identity/domain/blocked_user.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class UserProfileScreen extends ConsumerWidget {
  final String username;
  final String firebaseId;
  final String profilePictureUrl;

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.firebaseId,
    required this.profilePictureUrl,
  });

  Future<void> _blockUser(BuildContext context,
      WidgetRef ref,
      String username,
      String firebaseId,) async {
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(l10n.blockUser),
            content: Text(l10n.blockUserConfirmation(username)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.block,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Get the current user
        final currentUser = await ref.read(authStateProvider.future);
        if (currentUser == null) return;

        // Add to blocked users list
        final blockedUser = BlockedUser(
          username: username,
          firebaseId: firebaseId,
        );

        // Update the user's blocked list
        currentUser.blockedUsers.add(blockedUser);

        // Update in Firebase
        await ref.read(authServiceProvider).updateUserData(currentUser);

        if (context.mounted) {
          AppToast.showSuccess(context, l10n.userBlocked(username));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDialog.show(context, e);
        }
      }
    }
  }

  Future<void> _openDirectMessage(BuildContext context,
      WidgetRef ref,
      String username,
      String firebaseId,
      String profilePictureUrl,) async {
    try {
      // Get the current user
      final currentUser = await ref.read(authStateProvider.future);
      if (currentUser == null) return;

      // Get or create a DM thread with this user
      final thread = await ref
          .read(dmThreadServiceProvider)
          .getOrCreateDMThread(
        currentUserId: currentUser.firebaseID,
        currentUsername: currentUser.username,
        currentUserProfpic: currentUser.profilePictureUrl,
        partnerId: firebaseId,
        partnerName: username,
        partnerProfpic: profilePictureUrl,
      );

      if (context.mounted) {
        context.push('/dm/${thread.id}', extra: thread);
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
        title: Text(username),
      ),
      body: authState.when(
        data: (currentUser) {
          if (currentUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          // If the user is viewing their own profile, go back and optionally navigate to settings
          if (currentUser.firebaseID == firebaseId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && context.canPop()) {
                context.pop();
                // Optionally navigate to settings after popping
                context.push('/settings');
              } else {
                // Fallback if we can't pop (shouldn't normally happen)
                context.go('/settings');
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Check if user is already blocked
          final isBlocked = currentUser.blockedUsers
              .any((blockedUser) => blockedUser.firebaseId == firebaseId);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Profile Picture Section (non-editable)
                Center(
                  child: LazyProfileAvatar(
                    userId: firebaseId,
                    initialProfilePictureUrl: profilePictureUrl,
                    radius: 80,
                  ),
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  username,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _openDirectMessage(
                                context,
                                ref,
                                username,
                                firebaseId,
                                profilePictureUrl,
                              ),
                          icon: const Icon(Icons.message),
                          label: Text(l10n.directMessage),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isBlocked
                              ? null
                              : () =>
                              _blockUser(
                                context,
                                ref,
                                username,
                                firebaseId,
                              ),
                          icon: const Icon(Icons.block),
                          label: Text(isBlocked ? l10n.blocked : l10n.block),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor:
                            isBlocked ? Colors.grey : Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
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
