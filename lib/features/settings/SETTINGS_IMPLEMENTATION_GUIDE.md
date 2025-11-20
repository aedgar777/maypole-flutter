# Settings Feature Implementation Guide

## Overview

The settings feature allows users to manage their profile, including uploading and updating their
profile picture. This feature integrates with Firebase Storage for image storage and Firebase
Firestore for metadata storage.

## Feature Structure

```
lib/features/settings/
├── data/
│   └── services/
│       └── storage_service.dart       # Firebase Storage operations
├── domain/
│   └── settings_state.dart            # State management model
├── presentation/
│   ├── screens/
│   │   └── settings_screen.dart       # Main settings UI
│   └── viewmodels/
│       └── settings_viewmodel.dart    # Business logic
└── settings_providers.dart            # Riverpod providers
```

## Files Created

### 1. **storage_service.dart**

Handles all Firebase Storage operations:

- `uploadProfilePicture()` - Uploads image to Firebase Storage
- `updateUserProfilePictureUrl()` - Updates Firestore user document
- `deleteProfilePicture()` - Deletes profile picture from storage

**Storage Path Structure:**

```
profile_pictures/
  └── {userId}/
      └── profile.{extension}
```

### 2. **settings_state.dart**

Defines the state model for the settings feature with properties:

- `isLoading` - General loading state
- `error` - Error messages
- `uploadInProgress` - Image upload progress indicator
- `uploadProgress` - Upload progress percentage (future use)

### 3. **settings_viewmodel.dart**

Manages the business logic for settings operations:

- `uploadProfilePicture()` - Orchestrates image upload and profile update
- `clearError()` - Clears error messages

### 4. **settings_screen.dart**

The main UI for settings featuring:

- Circular profile picture display
- Camera/Gallery picker dialog
- Upload progress indicator
- User information display (username, email)
- Additional settings sections (placeholder implementations)
- Logout functionality with confirmation

### 5. **settings_providers.dart**

Riverpod providers for dependency injection:

- `storageServiceProvider` - Provides StorageService instance
- `settingsViewModelProvider` - Provides SettingsViewModel

## Firebase Setup Required

### Step 1: Enable Firebase Storage

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Storage** in the left sidebar
4. Click **Get Started**
5. Choose a location for your storage bucket (preferably same region as Firestore)
6. Click **Done**

### Step 2: Configure Storage Security Rules

Update your Firebase Storage security rules to allow authenticated users to upload their profile
pictures:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to upload/read/delete their own profile pictures
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if true; // Anyone can read profile pictures
      allow write, delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Validate file size (max 5MB) and image types
    match /profile_pictures/{userId}/profile.{extension} {
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

**Security Rules Explained:**

- Users can only upload to their own folder (userId must match auth.uid)
- All users can read profile pictures (for displaying in chats)
- Maximum file size: 5MB
- Only image files are allowed
- Files are stored at: `profile_pictures/{userId}/profile.{extension}`

### Step 3: Update Firestore Security Rules (if needed)

Ensure your Firestore rules allow users to update their profilePictureUrl:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can read their own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can update their own profile picture URL
      allow update: if request.auth != null 
                    && request.auth.uid == userId
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['profilePictureUrl']);
    }
  }
}
```

### Step 4: Android Configuration (if needed)

For Android, add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />
```

### Step 5: iOS Configuration (if needed)

For iOS, add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select a profile picture</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take a profile picture</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for video capture</string>
```

## Environment Variables

No additional environment variables are required. The feature uses the existing Firebase
configuration from `firebase_options.dart`.

## Local Variables to Configure

### In `storage_service.dart`:

**Line 23-24**: Storage path structure

```dart
// Current: profile_pictures/{userId}/profile.{extension}
// You can customize this path if needed
final storageRef = _storage.ref().child('profile_pictures/$userId/profile.$extension');
```

**Line 28-31**: Web support (currently not implemented)

```dart
if (kIsWeb) {
  // TODO: Implement web file upload
  // You'll need to use html.File and convert to bytes
  throw UnimplementedError('Web upload not implemented yet');
}
```

## Dependencies

The following dependencies were added to `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.7  # For selecting images from gallery/camera
```

All other dependencies (Firebase Storage, Firestore, Riverpod) were already in the project.

## Usage

### Navigating to Settings

From the home screen, users can tap the settings icon in the app bar to navigate to `/settings`.

### Uploading a Profile Picture

1. Tap the camera icon on the profile picture
2. Choose between Camera or Gallery
3. Select/capture an image
4. The image is automatically uploaded and the profile is updated
5. Success/error messages are displayed via SnackBar

### Code Integration

To access the current user's profile picture URL anywhere in the app:

```dart
final user = ref.watch(authStateProvider).value;
if (user != null && user.profilePictureUrl.isNotEmpty) {
  // Display profile picture
  CircleAvatar(
    backgroundImage: NetworkImage(user.profilePictureUrl),
  );
}
```

## Image Processing

The image picker is configured with the following constraints:

- **Max Width**: 1024px
- **Max Height**: 1024px
- **Image Quality**: 85%

This ensures reasonable file sizes while maintaining good quality. You can adjust these in
`settings_screen.dart` line 49-52.

## Error Handling

The feature handles the following error scenarios:

- User not logged in
- Upload failures
- Network errors
- File access permissions denied
- Invalid file types (handled by Firebase Storage rules)

All errors are displayed to the user via SnackBar notifications.

## Future Enhancements

The settings screen includes placeholder menu items for:

- Account Settings
- Notifications
- Privacy Settings
- Help
- About

These can be implemented by:

1. Creating new screens for each section
2. Adding routes in `app_router.dart`
3. Implementing the navigation in the respective `onTap` handlers

## Testing Checklist

- [ ] Firebase Storage is enabled in Firebase Console
- [ ] Storage security rules are updated
- [ ] Firestore security rules allow profilePictureUrl updates
- [ ] Android permissions are added (for Android)
- [ ] iOS permissions are added (for iOS)
- [ ] Image picker works from gallery
- [ ] Image picker works from camera
- [ ] Upload progress indicator displays correctly
- [ ] Profile picture updates in real-time across app
- [ ] Error messages display correctly
- [ ] Logout functionality works
- [ ] Navigation works correctly

## Troubleshooting

### "Permission denied" errors

- Check Firebase Storage security rules
- Verify user is authenticated
- Ensure userId matches authenticated user

### Image not uploading

- Check network connection
- Verify Firebase Storage is enabled
- Check file size (must be < 5MB)
- Verify file is an image type

### Profile picture not updating

- Check Firestore security rules
- Verify `profilePictureUrl` field is being updated
- Check that `authStateProvider` is watching Firestore changes

### Camera/Gallery not opening

- Verify platform-specific permissions are added
- Check device camera/storage permissions in settings
- Ensure `image_picker` dependency is installed

## Support

For issues or questions:

1. Check the Firebase Console for Storage errors
2. Review the Flutter logs for detailed error messages
3. Verify all security rules are correctly configured
4. Ensure all dependencies are up to date

## Related Files

- `lib/features/identity/domain/domain_user.dart` - User model with profilePictureUrl
- `lib/core/app_router.dart` - Routing configuration
- `lib/features/home/presentation/screens/home_screen.dart` - Settings button integration
- `lib/l10n/app_en.arb` - English localization strings
- `lib/l10n/app_es.arb` - Spanish localization strings
