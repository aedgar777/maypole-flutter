// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Maypole';

  @override
  String get appTitleDev => 'Maypole (Dev)';

  @override
  String get logout => 'Logout';

  @override
  String get maypolesTab => 'Maypoles';

  @override
  String get directMessagesTab => 'Direct Messages';

  @override
  String get noPlaceChats => 'No Maypole chats yet.';

  @override
  String get noDirectMessages => 'No direct messages yet.';

  @override
  String lastMessage(String time) {
    return 'Last message: $time';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String welcome(String email) {
    return 'Welcome $email';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get register => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get continueToApp => 'Continue to App';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get searchMaypoles => 'Search Maypoles';

  @override
  String get searchForMaypole => 'Search for a maypole';

  @override
  String get enterMessage => 'Enter a message';

  @override
  String get devEnvironment => 'DEV';
}
