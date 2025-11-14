# Quick Start: Build Configurations

## TL;DR - Get Started in 30 Seconds

### Android Studio

**Option 1: Run/Debug Dropdown (Fastest!) 🆕**

1. Click **Run Configuration dropdown** in the top bar (next to play button)
2. Select your configuration:
    - `Android Dev Debug` for development
    - `Android Prod Release` for production builds
3. Click the green play button ▶️

**Option 2: Build Variants Panel**
1. Open **Build Variants** panel (left sidebar or View → Tool Windows → Build Variants)
2. Select your variant:
    - `devDebug` for development
    - `prodRelease` for production builds
3. Click the green play button ▶️

📖 **[Run/Debug Menu Guide](./ANDROID_STUDIO_RUN_MENU_GUIDE.md)** - Learn to use the top bar dropdown

### Xcode

1. In Xcode, click the scheme dropdown (next to play/stop buttons)
2. Edit Scheme → Run → Build Configuration
3. Choose:
    - `dev-debug` for development
    - `prod-release` for production builds
4. Click the play button ▶️

## Four Build Configurations

| Name | Purpose | When to Use |
|------|---------|-------------|
| **dev-debug** | Development + Debugging | Daily development work |
| **dev-release** | Development + Optimized | Test performance with dev data |
| **prod-debug** | Production + Debugging | Debug issues in production environment |
| **prod-release** | Production + Optimized | App Store/Play Store releases |

## Command Line Quick Reference

### Android

```bash
# Dev Debug (most common for development)
flutter run --debug --flavor dev --dart-define=ENVIRONMENT=dev

# Prod Release (for store builds)
flutter build appbundle --release --flavor prod --dart-define=ENVIRONMENT=production
```

### iOS

```bash
# Dev Debug (most common for development)
flutter run --debug --dart-define=ENVIRONMENT=dev

# Prod Release (for store builds)
flutter build ipa --release --dart-define=ENVIRONMENT=production
```

## Build Scripts (Android Only)

We've created convenience scripts for Android builds:

```bash
./scripts/build-android-dev-debug.sh     # Dev debug APK
./scripts/build-android-dev-release.sh   # Dev release APK
./scripts/build-android-prod-debug.sh    # Prod debug APK
./scripts/build-android-prod-release.sh  # Prod release APK
./scripts/build-android-bundle.sh prod   # Prod app bundle for Play Store
```

## What Changed?

### Before

- Android: Simple dev/prod flavors
- iOS: Default Debug/Release configurations
- Inconsistent between platforms

### After

- **Both platforms**: 4 matching configurations
- **Android**: devDebug, devRelease, prodDebug, prodRelease
- **iOS**: dev-debug, dev-release, prod-debug, prod-release
- **Consistent** workflow across platforms

## App Identifiers

### Android

- Dev Debug: `app.maypole.maypole.dev.debug`
- Dev Release: `app.maypole.maypole.dev`
- Prod Debug: `app.maypole.maypole.debug`
- Prod Release: `app.maypole.maypole`

### iOS

- Dev: `app.maypole.maypole.dev`
- Prod: `app.maypole.maypole`

**Benefit**: You can install dev and prod versions side-by-side on the same device!

## Firebase Projects

- **dev**: Uses `maypole-flutter-dev` Firebase project
- **prod**: Uses `maypole-flutter-ce6c3` Firebase project

Configuration is automatic based on the build variant you select.

## Common Tasks

### Daily Development

```bash
# Android Studio: Select devDebug variant
# Xcode: Select dev-debug configuration
flutter run --debug --flavor dev --dart-define=ENVIRONMENT=dev
```

### Test Release Performance

```bash
# Android Studio: Select devRelease variant  
# Xcode: Select dev-release configuration
flutter run --release --flavor dev --dart-define=ENVIRONMENT=dev
```

### Build for Production

```bash
# Android
./scripts/build-android-bundle.sh prod

# iOS
flutter build ipa --release --dart-define=ENVIRONMENT=production
```

## Troubleshooting

### "Build variant not found" (Android)

```bash
flutter clean
flutter pub get
# In Android Studio: File → Sync Project with Gradle Files
```

### "Configuration not found" (iOS)

```bash
flutter clean
cd ios && pod install && cd ..
```

### Wrong Firebase project

Make sure you selected the correct build variant/configuration:

- Check the console output for "Environment Debug Info"
- Verify Build Variant panel (Android) or Scheme configuration (iOS)

## Need More Details?

- **[BUILD_CONFIGURATIONS_SUMMARY.md](./BUILD_CONFIGURATIONS_SUMMARY.md)** - Complete overview
- **[ANDROID_BUILD_CONFIGURATIONS.md](./ANDROID_BUILD_CONFIGURATIONS.md)** - Android deep dive
- **[ANDROID_STUDIO_ENV_GUIDE.md](./ANDROID_STUDIO_ENV_GUIDE.md)** - Android Studio UI guide

---

**Questions?** Check the console output when running - it shows which environment and configuration
is active.
