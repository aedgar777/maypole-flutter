import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

/// "Continue with Google", styled to Google's sign-in branding requirements:
/// the unmodified four-colour G mark on a white surface, with the wordmark
/// spelled the way Google requires. Deliberately not themed to match the rest
/// of the app — this is one of the few buttons whose appearance is not ours to
/// choose.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// Swaps the label for a spinner while the flow is in flight. The button
  /// keeps its footprint so the form does not jump.
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Height is fixed but width is left to the content, so the button hugs its
    // label the way the neighbouring Sign In button does. The Row already sizes
    // to its children; the parent Column supplies a bounded width, so the
    // Flexible below still has something to shrink against on a narrow screen
    // or with a longer translation.
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white70,
          foregroundColor: const Color(0xFF1F1F1F),
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_google_g.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.continueWithGoogle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A labelled rule that separates the Google button from the email form.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = Expanded(
      child: Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.orDivider,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
