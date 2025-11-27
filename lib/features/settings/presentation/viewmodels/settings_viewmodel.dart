import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/features/settings/data/services/storage_service.dart';
import 'package:maypole/features/settings/domain/settings_state.dart';
import 'package:maypole/features/identity/auth_providers.dart';

class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  /// Uploads a profile picture and updates the user's profile
  /// 
  /// [filePath] - The local file path of the image to upload
  Future<void> uploadProfilePicture(String filePath) async {
    final session = AppSession();
    final user = session.currentUser;

    if (user == null) {
      state = state.copyWith(error: 'User not logged in');
      return;
    }

    try {
      // Set upload in progress
      state = state.copyWith(
        uploadInProgress: true,
        error: null,
      );

      // Get storage service
      final storageService = StorageService();

      // Upload the file
      final downloadUrl = await storageService.uploadProfilePicture(
        user.firebaseID,
        filePath,
      );

      // Update Firestore
      await storageService.updateUserProfilePictureUrl(
        user.firebaseID,
        downloadUrl,
      );

      // Update local user object
      user.profilePictureUrl = downloadUrl;
      session.currentUser = user;

      // Invalidate auth state to refresh UI with new profile picture
      ref.invalidate(authStateProvider);

      // Reset state
      state = state.copyWith(
        uploadInProgress: false,
        uploadProgress: null,
      );
    } catch (e) {
      state = state.copyWith(
        uploadInProgress: false,
        uploadProgress: null,
        error: e.toString(),
      );
    }
  }

  /// Clears any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}
