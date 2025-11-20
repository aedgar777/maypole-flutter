# Firebase Setup Checklist for Settings Feature

Complete these steps to enable profile picture upload functionality.

## ☐ Step 1: Enable Firebase Storage

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **[YOUR_PROJECT_NAME]**
3. Click **Storage** in the left sidebar
4. Click **Get Started**
5. Choose production mode
6. Select a storage location (recommend same as Firestore)
7. Click **Done**

**Status**: ☐ Complete

---

## ☐ Step 2: Configure Storage Security Rules

1. In Firebase Console > Storage, click the **Rules** tab
2. Copy the rules from `FIREBASE_STORAGE_RULES.txt`
3. Replace the existing rules
4. Click **Publish**

**Current Default Rules:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**New Rules to Apply:**
See `FIREBASE_STORAGE_RULES.txt` in this directory.

**Status**: ☐ Complete

---

## ☐ Step 3: Verify Firestore Security Rules

Your users collection should allow authenticated users to update their `profilePictureUrl` field.

1. Go to Firebase Console > Firestore Database > Rules
2. Verify users can update their own `profilePictureUrl`:

```javascript
match /users/{userId} {
  allow update: if request.auth != null 
                && request.auth.uid == userId
                && request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['profilePictureUrl', /* other allowed fields */]);
}
```

**Status**: ☐ Complete

---

## ☐ Step 4: Android Configuration

### Add Permissions to `android/app/src/main/AndroidManifest.xml`

Add these lines inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />
```

**File Location**: `android/app/src/main/AndroidManifest.xml`

**Status**: ☐ Complete

---

## ☐ Step 5: iOS Configuration

### Add Permission Descriptions to `ios/Runner/Info.plist`

Add these lines inside the `<dict>` tag:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select a profile picture</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take a profile picture</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for video capture</string>
```

**File Location**: `ios/Runner/Info.plist`

**Status**: ☐ Complete

---

## ☐ Step 6: Install Dependencies

Run the following command to install the new dependency:

```bash
flutter pub get
```

**New Dependency Added**: `image_picker: ^1.0.7`

**Status**: ☐ Complete

---

## ☐ Step 7: Test the Feature

### Test Checklist

1. **Gallery Upload**
    - ☐ Open the app and navigate to Settings
    - ☐ Tap the camera icon on the profile picture
    - ☐ Select "Gallery"
    - ☐ Choose an image
    - ☐ Verify upload progress indicator shows
    - ☐ Verify success message appears
    - ☐ Verify profile picture updates

2. **Camera Upload**
    - ☐ Tap the camera icon again
    - ☐ Select "Camera"
    - ☐ Take a photo
    - ☐ Verify upload works
    - ☐ Verify profile picture updates

3. **Cross-App Display**
    - ☐ Navigate to home screen
    - ☐ Check if profile picture shows in DM threads (if applicable)
    - ☐ Restart app and verify picture persists

4. **Error Handling**
    - ☐ Test with airplane mode (should show error)
    - ☐ Test with very large image (should compress)
    - ☐ Verify error messages are user-friendly

5. **Firebase Console Verification**
    - ☐ Open Firebase Console > Storage
    - ☐ Navigate to `profile_pictures/[USER_ID]/`
    - ☐ Verify image file exists
    - ☐ Open Firebase Console > Firestore
    - ☐ Check user document for `profilePictureUrl` field
    - ☐ Verify URL matches Storage file

**Status**: ☐ Complete

---

## Optional: Step 8: Enable Firebase Storage CORS (for Web)

If you plan to support web, you'll need to configure CORS for Firebase Storage.

1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. Create a `cors.json` file:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

3. Run: `gsutil cors set cors.json gs://[YOUR-BUCKET-NAME]`

**Status**: ☐ Complete (Skip if not using web)

---

## Environment Variables Required

✅ **None** - The feature uses existing Firebase configuration from `firebase_options.dart`

---

## Verification Commands

### Check if dependencies are installed:

```bash
flutter pub get
flutter pub deps | grep image_picker
```

### Verify no linter errors:

```bash
flutter analyze lib/features/settings
```

### Run the app:

```bash
flutter run
```

---

## Troubleshooting

### Issue: "Permission denied" when uploading

**Solution**:

- Verify Storage rules are published
- Check user is authenticated
- Ensure userId in path matches authenticated user

### Issue: Image picker doesn't open

**Solution**:

- Check platform permissions are added
- Verify device camera/storage permissions in settings
- Run `flutter clean && flutter pub get`

### Issue: Profile picture doesn't update in UI

**Solution**:

- Check Firestore rules allow updating profilePictureUrl
- Verify authStateProvider is watching Firestore snapshots
- Check network connection

### Issue: Upload fails silently

**Solution**:

- Check Flutter device logs: `flutter logs`
- Verify Firebase Storage is enabled
- Check file size (must be < 5MB)

---

## Next Steps After Setup

Once all steps are complete:

1. ✅ Settings feature is fully functional
2. 🔄 Consider implementing web support (see storage_service.dart line 28-31)
3. 📱 Test on both iOS and Android devices
4. 🌐 Test in development and production environments
5. 📊 Monitor Firebase Storage usage in console
6. 🔒 Review security rules periodically

---

## Support Resources

- **Implementation Guide**: `SETTINGS_IMPLEMENTATION_GUIDE.md`
- **Firebase Storage Rules**: `FIREBASE_STORAGE_RULES.txt`
- **Feature README**: `README.md`
- **Firebase Documentation**: https://firebase.google.com/docs/storage
- **image_picker Documentation**: https://pub.dev/packages/image_picker

---

## Summary

**Files Created**: 5 Dart files + 3 documentation files  
**Dependencies Added**: 1 (image_picker)  
**Firebase Services Used**: Storage, Firestore  
**Platforms Supported**: Android, iOS (Web needs additional work)  
**Localization**: English, Spanish

**Estimated Setup Time**: 15-30 minutes

---

**Last Updated**: Generated automatically during feature creation
