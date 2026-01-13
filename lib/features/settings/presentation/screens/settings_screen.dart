import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/settings/settings_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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

      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, e);
      }
    }
  }

  Future<void> _openHelpAndFeedback() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'info@maypole.app',
        query: 'body=Describe your issue:',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorOpeningEmail),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, e);
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
                      CachedProfileAvatar(
                        imageUrl: user.profilePictureUrl,
                        radius: 80,
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
                const SizedBox(height: 32),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                // Settings sections
                GestureDetector(
                  onTap: () {
                    context.push('/settings/account');
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(l10n.accountSettings),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/settings/preferences');
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: const ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Preferences'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/privacy-policy');
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: Text(l10n.privacy),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openHelpAndFeedback,
                  child: Container(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(l10n.help),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                GestureDetector(
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
                  child: Container(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
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
