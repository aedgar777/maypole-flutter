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
  String get noPlaceChats => 'No place chats yet.';

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

  @override
  String get settings => 'Settings';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get help => 'Help & Feedback';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get at => 'at';

  @override
  String get searchPlaces => 'Search Places';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get systemNotifications => 'System Notifications';

  @override
  String get notificationPermissionGranted => 'Notifications enabled';

  @override
  String get notificationPermissionGrantedDescription =>
      'You will receive notifications for your selected types';

  @override
  String get notificationPermissionDenied => 'Notifications Disabled';

  @override
  String get notificationPermissionDeniedDescription =>
      'Enable notifications to receive updates';

  @override
  String get notificationPermissionDeniedMessage =>
      'Notification permission was denied. To enable notifications, please go to Settings and allow notifications for Maypole.';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get taggingNotifications => 'Tagging Notifications';

  @override
  String get taggingNotificationsDescription =>
      'Get notified when someone tags you in a message';

  @override
  String get directMessageNotifications => 'Direct Message Notifications';

  @override
  String get directMessageNotificationsDescription =>
      'Get notified when you receive a direct message';

  @override
  String get enableSystemNotificationsFirst =>
      'Enable system notifications first to configure notification types';

  @override
  String get noUsersFound => 'No users found';
}
