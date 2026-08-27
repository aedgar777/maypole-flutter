import 'package:maypole/l10n/generated/app_localizations.dart';

class StringUtils {
  // Field length constraints
  static const int maxUsernameLength = 30;
  static const int maxEmailLength = 254; // RFC 5321 standard
  static const int maxPasswordLength = 128;
  
  /// Derives a username suggestion from what an identity provider told us.
  ///
  /// Google gives us a display name and an email but no username, so this
  /// produces a starting point for the field on the username screen. It is only
  /// ever a suggestion: the user can replace it, and whatever they submit still
  /// goes through [validateUsername] and the availability check.
  ///
  /// Returns an empty string when nothing usable survives — a name of only
  /// spaces or accented characters, say — which simply leaves the field blank
  /// rather than pre-filling it with something malformed.
  static String suggestUsername({String? displayName, String? email}) {
    final source = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : (email ?? '').split('@').first;

    // Same character set [validateUsername] enforces, so a suggestion is never
    // rejected the instant it appears.
    final cleaned = source.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

    if (cleaned.length < 3) return '';

    return cleaned.length > maxUsernameLength
        ? cleaned.substring(0, maxUsernameLength)
        : cleaned;
  }

  static String? validateUsername(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterUsername;
    }

    if (value.length < 3) {
      return l10n.usernameMinLength;
    }

    if (value.length > maxUsernameLength) {
      return l10n.usernameMaxLength(maxUsernameLength);
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return l10n.usernameInvalidCharacters;
    }

    return null;
  }

  static String? validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterEmail;
    }

    if (value.length > maxEmailLength) {
      return l10n.emailMaxLength(maxEmailLength);
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return l10n.pleaseEnterValidEmail;
    }

    return null;
  }

  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }

    if (value.length < 6) {
      return l10n.passwordMinLength;
    }

    if (value.length > maxPasswordLength) {
      return l10n.passwordMaxLength(maxPasswordLength);
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String? password, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseConfirmPassword;
    }

    if (value != password) {
      return l10n.passwordsDoNotMatch;
    }

    return null;
  }
}