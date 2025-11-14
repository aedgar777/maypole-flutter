# Build Configurations Summary

This document provides a high-level overview of the build configurations across iOS and Android
platforms.

## Overview

Your app now has matching build configurations across both iOS and Android platforms:

- **dev-debug**: Development environment with debugging enabled
- **dev-release**: Development environment with release optimizations
- **prod-debug**: Production environment with debugging enabled
- **prod-release**: Production environment with release optimizations

## Quick Reference Table

| Configuration | iOS (Xcode) | Android (Gradle) | Firebase Project | Usage |
|---------------|-------------|------------------|------------------|-------|
| **dev-debug** | dev-debug | devDebug | maypole-flutter-dev | Daily development |
| **dev-release** | dev-release | devRelease | maypole-flutter-dev | Testing performance |
| **prod-debug** | prod-debug | prodDebug | maypole-flutter-ce6c3 | Production debugging |
| **prod-release** | prod-release | prodRelease | maypole-flutter-ce6c3 | App Store/Play Store |

## Platform Details

### iOS (Xcode)

**Build Configurations:**

- dev-debug
- dev-release
- prod-debug
- prod-release
- Profile (Flutter-specific)

**Bundle IDs:**

- Dev: `app.maypole.maypole.dev`
- Prod: `app.maypole.maypole`

**Selecting in Xcode:**

1. Click on scheme dropdown (next to play/stop buttons)
2. Select "Edit Scheme"
3. Choose build configuration under "Run" → "Build Configuration"

### Android (Gradle)

**Build Variants:**

- devDebug (dev-debug)
- devRelease (dev-release)
- prodDebug (prod-debug)
- prodRelease (prod-release)
- devProfile, prodProfile (Flutter-specific)

**Application IDs:**

- Dev Debug: `app.maypole.maypole.dev.debug`
- Dev Release: `app.maypole.maypole.dev`
- Prod Debug: `app.maypole.maypole.debug`
- Prod Release: `app.maypole.maypole`

**Selecting in Android Studio:**

1. Open "Build Variants" panel (View → Tool Windows → Build Variants)
2. Select variant from dropdown
3. Click play button to run

## Build Scripts

### iOS

```bash
# Build from Xcode or use xcodebuild:
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration dev-debug \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Android

```bash
# Use provided scripts:
./scripts/build-android-dev-debug.sh
./scripts/build-android-dev-release.sh
./scripts/build-android-prod-debug.sh
./scripts/build-android-prod-release.sh

# Or use Flutter directly:
flutter build apk --debug --flavor dev --dart-define=ENVIRONMENT=dev
flutter build apk --release --flavor prod --dart-define=ENVIRONMENT=production
```

## Running the App

### iOS (Xcode)

```bash
# From command line:
flutter run --debug --dart-define=ENVIRONMENT=dev -d "iPhone 15"
flutter run --release --dart-define=ENVIRONMENT=production -d "iPhone 15"
```

### Android

```bash
# Dev Debug
flutter run --debug --flavor dev --dart-define=ENVIRONMENT=dev

# Dev Release
flutter run --release --flavor dev --dart-define=ENVIRONMENT=dev

# Prod Debug
flutter run --debug --flavor prod --dart-define=ENVIRONMENT=production

# Prod Release  
flutter run --release --flavor prod --dart-define=ENVIRONMENT=production
```

## App Store / Play Store Builds

### iOS

1. In Xcode, select "Any iOS Device (arm64)"
2. Select scheme with "prod-release" configuration
3. Product → Archive
4. Distribute to App Store Connect

```bash
# Or via command line:
flutter build ipa --release --dart-define=ENVIRONMENT=production
```

### Android

```bash
# Build App Bundle for Play Store:
./scripts/build-android-bundle.sh prod

# Or manually:
flutter build appbundle --release --flavor prod --dart-define=ENVIRONMENT=production
```

**Output:** `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

## Environment Configuration

### Firebase Setup

Each environment uses separate Firebase projects:

**Development (dev):**

- Project: `maypole-flutter-dev`
- iOS: Uses dev-specific configuration in scheme
- Android: `android/app/src/dev/google-services.json`

**Production (prod):**

- Project: `maypole-flutter-ce6c3`
- iOS: Uses prod-specific configuration in scheme
- Android: `android/app/src/prod/google-services.json`

### Environment Variables

Managed via `env.local` file:

```bash
# Switch to development
./scripts/switch-to-dev.sh

# Switch to production
./scripts/switch-to-prod.sh
```

## Development Workflow

### Daily Development

- **iOS**: Use dev-debug configuration
- **Android**: Use devDebug variant
- Hot reload enabled, full debugging

### Testing Performance

- **iOS**: Use dev-release configuration
- **Android**: Use devRelease variant
- Tests release optimizations with dev environment

### Pre-Production Testing

- **iOS**: Use prod-debug configuration
- **Android**: Use prodDebug variant
- Tests against production environment with debugging

### Store Releases

- **iOS**: Use prod-release configuration
- **Android**: Use prodRelease variant
- Fully optimized for production

## Key Differences

### Application IDs

**iOS:**

- Dev and Prod use different bundle IDs
- Can install both simultaneously on same device

**Android:**

- Dev Debug and Prod Debug have `.debug` suffix
- All four variants have unique app IDs
- Can install all four simultaneously on same device

### Build System

**iOS:**

- Uses Xcode build configurations
- Configurations defined in project.pbxproj
- Selected via scheme

**Android:**

- Uses Gradle product flavors + build types
- Configurations defined in build.gradle.kts
- Selected via Build Variants panel

## Troubleshooting

### iOS Issues

```bash
# Clean build
flutter clean
cd ios && pod deinstall && pod install && cd ..
flutter build ios --debug --dart-define=ENVIRONMENT=dev
```

### Android Issues

```bash
# Clean build
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter build apk --debug --flavor dev --dart-define=ENVIRONMENT=dev
```

### Both Platforms

```bash
# Complete clean
flutter clean
rm -rf ios/Pods ios/.symlinks ios/Podfile.lock
rm -rf android/.gradle android/app/build
flutter pub get
```

## Documentation

- **[ANDROID_BUILD_CONFIGURATIONS.md](./ANDROID_BUILD_CONFIGURATIONS.md)** - Detailed Android guide
- **[ANDROID_STUDIO_ENV_GUIDE.md](./ANDROID_STUDIO_ENV_GUIDE.md)** - Android Studio UI guide
- **[ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md)** - Firebase configuration
- **[ENVIRONMENT_SWITCHING.md](./ENVIRONMENT_SWITCHING.md)** - Environment switching

## Verification

### Check iOS Configurations

```bash
# List all build configurations
xcodebuild -workspace ios/Runner.xcworkspace -list
```

### Check Android Variants

```bash
# List all build variants
./android/gradlew -p android app:tasks --all | grep "^assemble"
```

Expected output includes:

- `assembleDevDebug`
- `assembleDevRelease`
- `assembleProdDebug`
- `assembleProdRelease`

## Success Criteria

✅ iOS has 4 build configurations matching Android
✅ Android has 4 build variants matching iOS
✅ Each environment uses correct Firebase project
✅ Dev and Prod can be installed simultaneously
✅ Build scripts work for all configurations
✅ App names differentiate between environments

---

**Status:** ✅ Complete - iOS and Android build configurations are now aligned and match across both
platforms.
