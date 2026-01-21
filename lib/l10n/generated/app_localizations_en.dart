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
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get username => 'Username';

  @override
  String get register => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseEnterUsername => 'Please enter a username';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String usernameMaxLength(int maxLength) {
    return 'Username must be no more than $maxLength characters';
  }

  @override
  String get usernameInvalidCharacters =>
      'Username can only contain letters, numbers, and underscores';

  @override
  String emailMaxLength(int maxLength) {
    return 'Email must be no more than $maxLength characters';
  }

  @override
  String passwordMaxLength(int maxLength) {
    return 'Password must be no more than $maxLength characters';
  }

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

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
  String get help => 'Help';

  @override
  String get feedback => 'Feedback';

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

  @override
  String get errorTitle => 'Error';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get accountDeleted => 'Account deleted successfully';

  @override
  String get delete => 'Delete';

  @override
  String get directMessage => 'Direct Message';

  @override
  String get block => 'Block';

  @override
  String get blocked => 'Blocked';

  @override
  String get blockUser => 'Block User';

  @override
  String blockUserConfirmation(String username) {
    return 'Are you sure you want to block $username? You will no longer see their messages.';
  }

  @override
  String userBlocked(String username) {
    return '$username has been blocked';
  }

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get noBlockedUsers => 'You haven\'t blocked any users';

  @override
  String get unblock => 'Unblock';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String unblockUserConfirmation(String username) {
    return 'Are you sure you want to unblock $username?';
  }

  @override
  String userUnblocked(String username) {
    return '$username has been unblocked';
  }

  @override
  String get errorOpeningEmail => 'Could not open email client';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get deleteMessage => 'Delete';

  @override
  String tagUser(String name) {
    return 'Tag $name';
  }

  @override
  String get viewProfile => 'View Profile';

  @override
  String get userNotFound => 'User not found';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get deletionCancelled => 'Deletion cancelled';

  @override
  String get conversationDeleted => 'Conversation deleted';

  @override
  String errorDeletingMessage(String error) {
    return 'Error deleting message: $error';
  }

  @override
  String errorDeletingConversation(String error) {
    return 'Error deleting conversation: $error';
  }

  @override
  String get emailAddress => 'Email Address';

  @override
  String get validated => 'Verified';

  @override
  String get notValidated => 'Not Verified';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get resendVerification => 'Resend Verification';

  @override
  String get verificationEmailSent =>
      'Verification email sent! Please check your inbox.';

  @override
  String get registrationSuccessTitle => 'Welcome to Maypole!';

  @override
  String registrationSuccessMessage(String email) {
    return 'Your account has been created successfully! We\'ve sent a verification email to $email. Please check your inbox and verify your email to unlock all features.';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get hasAddedAnImage => 'has added an image';

  @override
  String get chatHere => 'Chat Here';

  @override
  String get selectPlaceOnMap => 'Tap anywhere on the map to select a place';
}
