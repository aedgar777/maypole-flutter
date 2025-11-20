import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/settings/settings_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectImageSource),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: Text(AppLocalizations.of(context)!.gallery),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: Text(AppLocalizations.of(context)!.camera),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
            ),
      );

      if (source == null) return;

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Upload image
      await ref.read(settingsViewModelProvider.notifier).uploadProfilePicture(
          image.path);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePictureUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final settingsState = ref.watch(settingsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        backgroundImage: user.profilePictureUrl.isNotEmpty
                            ? NetworkImage(user.profilePictureUrl)
                            : null,
                        child: user.profilePictureUrl.isEmpty
                            ? Icon(
                          Icons.person,
                          size: 80,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        )
                            : null,
                      ),
                      // Upload indicator overlay
                      if (settingsState.uploadInProgress)
                        Positioned.fill(
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.black54,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Edit button
                      if (!settingsState.uploadInProgress)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onPrimary,
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  user.username,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  user.email,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                // Settings sections
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(l10n.accountSettings),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to account settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoon)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(l10n.notifications),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to notification settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoon)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(l10n.privacy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to privacy settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoon)),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(l10n.help),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to help
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoon)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.about),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to about
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoon)),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final navigator = GoRouter.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            title: Text(l10n.logout),
                            content: Text(l10n.logoutConfirmation),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  l10n.logout,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      if (!mounted) return;
                      await ref.read(authServiceProvider).signOut();
                      if (!mounted) return;
                      navigator.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(
              child: Text(l10n.error(error.toString())),
            ),
      ),
    );
  }
}
