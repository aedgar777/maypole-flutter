import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import './widgets/auth_form_field.dart';
import '../auth_providers.dart';

/// The one thing Google cannot tell us: what this person wants to be called.
///
/// Reached only from a first-time Google sign-in. The Firebase account already
/// exists by the time this screen is shown, but the Firestore profile does not
/// — so this screen is the last step of sign-up, not an optional extra, and
/// leaving it without submitting has to unwind the account rather than leak it.
class GoogleUsernameScreen extends ConsumerStatefulWidget {
  /// Where to send the user once the profile is created. Carried through from
  /// the deep link that sent them to login in the first place.
  final String? returnTo;

  const GoogleUsernameScreen({super.key, this.returnTo});

  @override
  ConsumerState<GoogleUsernameScreen> createState() =>
      _GoogleUsernameScreenState();
}

class _GoogleUsernameScreenState extends ConsumerState<GoogleUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;

  /// Set once navigation onward has been scheduled, so it happens once.
  bool _navigated = false;

  /// Whether the suggested username has been placed in the field yet.
  ///
  /// Tracked separately from "the field is empty" so that a user who
  /// deliberately clears the box does not get the suggestion pushed back at
  /// them on the next rebuild.
  bool _seededSuggestion = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _seedSuggestion(ref.read(googleProfileSetupProvider)?.suggestedUsername);
  }

  /// Pre-fills the field from the Google display name, once.
  ///
  /// Called from both [initState] and [build] because the two entry points to
  /// this screen populate the provider at different times: a sign-in started in
  /// this session sets it before navigating, while one resumed after a relaunch
  /// is restored by the router a microtask later — after this screen has
  /// already been constructed.
  void _seedSuggestion(String? suggestion) {
    if (_seededSuggestion) return;
    if (suggestion == null || suggestion.isEmpty) return;
    _seededSuggestion = true;
    _usernameController.text = suggestion;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(googleUsernameViewModelProvider.notifier)
        .submit(_usernameController.text.trim());
  }

  String get _postAuthRoute {
    final returnTo = widget.returnTo;
    if (returnTo == null || returnTo.isEmpty) return '/home';

    final uri = Uri.tryParse(returnTo);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return '/home';

    return returnTo.startsWith('/') ? returnTo : '/$returnTo';
  }

  /// Confirms before throwing away a half-created account, then unwinds it.
  ///
  /// The account is invisible to the user — they think they are simply backing
  /// out of a sign-up — so the wording talks about cancelling rather than about
  /// deleting anything.
  Future<void> _confirmAbandon() async {
    final l10n = AppLocalizations.of(context)!;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelSignUpTitle),
        content: Text(l10n.cancelSignUpMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelSignUpKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.cancelSignUpConfirm,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return;

    await ref.read(googleUsernameViewModelProvider.notifier).abandon();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(googleUsernameViewModelProvider);
    final pending = ref.watch(googleProfileSetupProvider);

    _seedSuggestion(pending?.suggestedUsername);

    // The profile document is written, but that is not the same as the app
    // knowing about it: [authStateProvider] only reports the user once the
    // Firestore listener delivers the new document. Navigating on the write
    // alone would reach the router's redirect while it still sees a signed-out
    // user, and it would bounce us to the login screen. Wait for the stream.
    if (state.isComplete) {
      final authUser = ref.watch(authStateProvider).value;

      if (authUser != null && !_navigated) {
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(_postAuthRoute);
        });
      }

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      // Never let the back gesture leave silently: the account it would strand
      // is already real.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || state.isLoading) return;
        _confirmAbandon();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.chooseUsernameTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: state.isLoading ? null : _confirmAbandon,
          ),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                    Text(
                      l10n.chooseUsernameDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (pending != null && pending.email.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.signedInAsGoogle(pending.email),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    AuthFormField(
                      controller: _usernameController,
                      labelText: l10n.username,
                      maxLength: StringUtils.maxUsernameLength,
                      onFieldSubmitted: (_) => _handleSubmit(),
                      validator: (value) =>
                          StringUtils.validateUsername(value, l10n),
                    ),
                    const SizedBox(height: 30),
                    if (state.isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        child: Text(
                          l10n.finishSignUp,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          state.errorMessage!,
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
    );
  }
}
