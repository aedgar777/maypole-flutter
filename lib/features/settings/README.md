# Settings Feature

A comprehensive settings feature for the Maypole app with profile picture management.

## Quick Start

1. **Enable Firebase Storage**: See `FIREBASE_STORAGE_RULES.txt` for setup instructions
2. **Run the app**: Navigate to Settings from the home screen via the settings icon
3. **Upload a profile picture**: Tap the camera icon on the circular avatar

## Feature Structure

```
lib/features/settings/
├── data/
│   └── services/
│       └── storage_service.dart           # Firebase Storage operations
├── domain/
│   └── settings_state.dart                # State management
├── presentation/
│   ├── screens/
│   │   └── settings_screen.dart           # Main UI
│   └── viewmodels/
│       └── settings_viewmodel.dart        # Business logic
├── settings_providers.dart                # Riverpod providers
├── FIREBASE_STORAGE_RULES.txt            # Firebase Storage rules to copy
├── SETTINGS_IMPLEMENTATION_GUIDE.md      # Detailed implementation guide
└── README.md                              # This file
```

## Key Features

✅ Profile picture upload from camera or gallery  
✅ Real-time profile picture display  
✅ Upload progress indicator  
✅ Error handling and user feedback  
✅ Firebase Storage integration  
✅ Firestore synchronization  
✅ Image optimization (max 1024x1024, 85% quality)  
✅ Secure storage with Firebase rules  
✅ Logout with confirmation  
✅ Localized (English & Spanish)

## Integration Points

### Modified Files

- `lib/core/app_router.dart` - Added `/settings` route
- `lib/features/home/presentation/screens/home_screen.dart` - Added settings button
- `lib/l10n/app_en.arb` - Added English strings
- `lib/l10n/app_es.arb` - Added Spanish strings
- `pubspec.yaml` - Added `image_picker` dependency

### New Dependencies

- `image_picker: ^1.0.7` - For camera/gallery access

## Firebase Setup Required

### 1. Enable Firebase Storage

```bash
1. Go to Firebase Console
2. Navigate to Storage
3. Click "Get Started"
4. Choose storage location
```

### 2. Add Storage Rules

Copy the rules from `FIREBASE_STORAGE_RULES.txt` to Firebase Console > Storage > Rules

### 3. Platform-Specific Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select a profile picture</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take a profile picture</string>
```

## Usage Example

### Display Profile Picture Anywhere

```dart
final user = ref.watch(authStateProvider).value;
if (user != null && user.profilePictureUrl.isNotEmpty) {
  CircleAvatar(
    backgroundImage: NetworkImage(user.profilePictureUrl),
  );
}
```

### Navigate to Settings

```dart
context.push('/settings');
```

## Architecture

This feature follows the project's established architecture pattern:

- **Domain Layer**: Contains state models and business entities
- **Data Layer**: Firebase Storage and Firestore operations
- **Presentation Layer**: UI screens, widgets, and view models
- **Providers**: Riverpod dependency injection

## State Management

Uses Riverpod with the following providers:

- `settingsViewModelProvider` - Manages settings state and operations
- `storageServiceProvider` - Provides Firebase Storage service
- `authStateProvider` - Watches user authentication state (existing)

## Testing

Before deploying to production:

- [ ] Test image upload from gallery
- [ ] Test image upload from camera
- [ ] Verify Firebase Storage rules
- [ ] Test on both Android and iOS
- [ ] Verify profile picture displays across app
- [ ] Test error scenarios (no internet, permission denied, etc.)

## Troubleshooting

See `SETTINGS_IMPLEMENTATION_GUIDE.md` for detailed troubleshooting steps.

Common issues:

- **Permission denied**: Check Firebase Storage rules
- **Image not uploading**: Verify Firebase Storage is enabled
- **Camera not opening**: Check platform permissions

## Future Enhancements

The settings screen includes placeholders for:

- Account Settings
- Notification Preferences
- Privacy Settings
- Help & Support
- About

Implement these by creating new screens and updating the navigation handlers.

## Documentation

- `SETTINGS_IMPLEMENTATION_GUIDE.md` - Complete implementation details
- `FIREBASE_STORAGE_RULES.txt` - Firebase Storage security rules

## Support

For questions or issues, refer to the implementation guide or check:

1. Firebase Console for Storage errors
2. Flutter device logs for detailed errors
3. Firebase Storage rules configuration
