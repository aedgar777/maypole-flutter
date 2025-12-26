import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Maypole'**
  String get appTitle;

  /// The title of the application in development mode
  ///
  /// In en, this message translates to:
  /// **'Maypole (Dev)'**
  String get appTitleDev;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Tab label for Maypoles
  ///
  /// In en, this message translates to:
  /// **'Maypoles'**
  String get maypolesTab;

  /// Tab label for Direct Messages
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get directMessagesTab;

  /// Message shown when there are no place chats
  ///
  /// In en, this message translates to:
  /// **'No place chats yet.'**
  String get noPlaceChats;

  /// Message shown when there are no direct messages
  ///
  /// In en, this message translates to:
  /// **'No direct messages yet.'**
  String get noDirectMessages;

  /// Last message timestamp
  ///
  /// In en, this message translates to:
  /// **'Last message: {time}'**
  String lastMessage(String time);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Text for users who already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// Validation message for empty email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Validation message for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Validation message for empty password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Validation message for password minimum length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Validation message for empty username
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseEnterUsername;

  /// Validation message for username minimum length
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinLength;

  /// Validation message for username maximum length
  ///
  /// In en, this message translates to:
  /// **'Username must be no more than {maxLength} characters'**
  String usernameMaxLength(int maxLength);

  /// Validation message for invalid username characters
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get usernameInvalidCharacters;

  /// Validation message for email maximum length
  ///
  /// In en, this message translates to:
  /// **'Email must be no more than {maxLength} characters'**
  String emailMaxLength(int maxLength);

  /// Validation message for password maximum length
  ///
  /// In en, this message translates to:
  /// **'Password must be no more than {maxLength} characters'**
  String passwordMaxLength(int maxLength);

  /// Validation message for empty password confirmation
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// Validation message when passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Title for the search screen
  ///
  /// In en, this message translates to:
  /// **'Search Maypoles'**
  String get searchMaypoles;

  /// Hint text for search field
  ///
  /// In en, this message translates to:
  /// **'Search for a maypole'**
  String get searchForMaypole;

  /// Hint text for message input field
  ///
  /// In en, this message translates to:
  /// **'Enter a message'**
  String get enterMessage;

  /// Label indicating development environment
  ///
  /// In en, this message translates to:
  /// **'DEV'**
  String get devEnvironment;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Dialog title for selecting image source
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Gallery option for image picker
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera option for image picker
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Success message for profile picture update
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get profilePictureUpdated;

  /// Account settings menu item
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// Notifications menu item
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Privacy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Help menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get help;

  /// Privacy Policy screen title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Message for features not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// Confirmation message for logout
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for today's date
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for yesterday's date
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Label for very recent activity
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Label for activity minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Label for activity hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Separator between date and time
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// Tooltip for search/add button
  ///
  /// In en, this message translates to:
  /// **'Search Places'**
  String get searchPlaces;

  /// Notification settings screen title
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// System notification permission section title
  ///
  /// In en, this message translates to:
  /// **'System Notifications'**
  String get systemNotifications;

  /// Message when notification permission is granted
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationPermissionGranted;

  /// Description shown when permission is granted
  ///
  /// In en, this message translates to:
  /// **'You will receive notifications for your selected types'**
  String get notificationPermissionGrantedDescription;

  /// Dialog title when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationPermissionDenied;

  /// Description shown when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive updates'**
  String get notificationPermissionDeniedDescription;

  /// Message explaining how to enable notifications in settings
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. To enable notifications, please go to Settings and allow notifications for Maypole.'**
  String get notificationPermissionDeniedMessage;

  /// Button text to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Button text to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Section header for notification types
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// Toggle label for tagging notifications
  ///
  /// In en, this message translates to:
  /// **'Tagging Notifications'**
  String get taggingNotifications;

  /// Description for tagging notifications
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone tags you in a message'**
  String get taggingNotificationsDescription;

  /// Toggle label for direct message notifications
  ///
  /// In en, this message translates to:
  /// **'Direct Message Notifications'**
  String get directMessageNotifications;

  /// Description for direct message notifications
  ///
  /// In en, this message translates to:
  /// **'Get notified when you receive a direct message'**
  String get directMessageNotificationsDescription;

  /// Message shown when system permission is needed
  ///
  /// In en, this message translates to:
  /// **'Enable system notifications first to configure notification types'**
  String get enableSystemNotificationsFirst;

  /// Message shown when no users match the search query
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// Title for error dialogs
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Button text to dismiss a dialog
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Button text to delete account
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Title for delete account dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// Confirmation message for account deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountConfirmation;

  /// Success message after account deletion
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Direct message button text
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessage;

  /// Block user button text
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// Text shown when user is already blocked
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// Block user dialog title
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// Confirmation message for blocking a user
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {username}? You will no longer see their messages.'**
  String blockUserConfirmation(String username);

  /// Success message after blocking a user
  ///
  /// In en, this message translates to:
  /// **'{username} has been blocked'**
  String userBlocked(String username);

  /// Blocked users screen title
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// Message shown when user has no blocked users
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked any users'**
  String get noBlockedUsers;

  /// Unblock button text
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// Unblock user dialog title
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// Confirmation message for unblocking a user
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {username}?'**
  String unblockUserConfirmation(String username);

  /// Success message after unblocking a user
  ///
  /// In en, this message translates to:
  /// **'{username} has been unblocked'**
  String userUnblocked(String username);

  /// Error message when email client cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open email client'**
  String get errorOpeningEmail;

  /// Generic message for unknown errors
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// Delete message option in context menu
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteMessage;

  /// Tag user option in context menu
  ///
  /// In en, this message translates to:
  /// **'Tag {name}'**
  String tagUser(String name);

  /// View profile option in context menu
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// Error message when user cannot be found
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// Success message after deleting a message
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// Message when deletion is cancelled
  ///
  /// In en, this message translates to:
  /// **'Deletion cancelled'**
  String get deletionCancelled;

  /// Success message after deleting a conversation
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// Error message when message deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting message: {error}'**
  String errorDeletingMessage(String error);

  /// Error message when conversation deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting conversation: {error}'**
  String errorDeletingConversation(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
