import 'package:maypole/l10n/generated/app_localizations.dart';

class StringUtils {
  // Field length constraints
  static const int maxUsernameLength = 30;
  static const int maxEmailLength = 254; // RFC 5321 standard
  static const int maxPasswordLength = 128;
  
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