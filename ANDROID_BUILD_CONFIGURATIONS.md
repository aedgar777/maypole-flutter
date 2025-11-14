# Android Build Configurations Guide

This guide explains the Android build configurations that match the iOS setup in Xcode.

## Overview

Your Android app now has four build variants that mirror the iOS configurations:

| Configuration | Flavor | Build Type | Application ID | Description |
|---------------|--------|------------|----------------|-------------|
| **dev-debug** | dev | debug | app.maypole.maypole.dev.debug | Development with debugging |
| **dev-release** | dev | release | app.maypole.maypole.dev | Development optimized build |
| **prod-debug** | prod | debug | app.maypole.maypole.debug | Production with debugging |
| **prod-release** | prod | release | app.maypole.maypole | Production optimized build |

## How It Works

Android uses **Product Flavors** and **Build Types** to create build variants:

- **Product Flavors**: `dev` and `prod` (environment-based)
- **Build Types**: `debug` and `release` (optimization level)
- **Build Variants**: Combinations of flavor + build type

## Build Configuration Details

### Dev-Debug (devDebug)

```gradle
applicationId: app.maypole.maypole.dev.debug
versionNameSuffix: -dev-debug
appName: Maypole Dev
Firebase: maypole-flutter-dev
Debuggable: Yes
Minified: No
```

### Dev-Release (devRelease)

```gradle
applicationId: app.maypole.maypole.dev
versionNameSuffix: -dev
appName: Maypole Dev
Firebase: maypole-flutter-dev
Debuggable: No
Minified: Yes
```

### Prod-Debug (prodDebug)

```gradle
applicationId: app.maypole.maypole.debug
versionNameSuffix: -debug
appName: Maypole
Firebase: maypole-flutter-ce6c3
Debuggable: Yes
Minified: No
```

### Prod-Release (prodRelease)

```gradle
applicationId: app.maypole.maypole
appName: Maypole
Firebase: maypole-flutter-ce6c3
Debuggable: No
Minified: Yes
```

## Building in Android Studio

### Using the Build Variants Panel

1. **Open Build Variants Panel**
    - Click on `Build Variants` tab on the left side of Android Studio
    - Or go to `View → Tool Windows → Build Variants`

2. **Select Your Build Variant**
    - Click the dropdown under "Active Build Variant"
    - Choose from:
        - `devDebug` (dev-debug)
        - `devRelease` (dev-release)
        - `prodDebug` (prod-debug)
        - `prodRelease` (prod-release)

3. **Run or Build**
    - Click the green play button to run on a device/emulator
    - Or go to `Build → Build Bundle(s) / APK(s) → Build APK(s)`

### Using Run Configurations

1. **Select Run Configuration Dropdown** (next to play button)
2. **Choose:**
    - `maypole (dev)` → Runs devDebug
    - `maypole (production)` → Runs prodDebug
    - `maypole (dev-release)` → Runs devRelease
    - `maypole (prod-release)` → Runs prodRelease

## Building via Command Line

### Using Build Scripts (Recommended)

We've created convenient build scripts that match the iOS workflow:

```bash
# Dev Debug
./scripts/build-android-dev-debug.sh

# Dev Release
./scripts/build-android-dev-release.sh

# Prod Debug
./scripts/build-android-prod-debug.sh

# Prod Release
./scripts/build-android-prod-release.sh

# App Bundle for Play Store (default: prod)
./scripts/build-android-bundle.sh
# Or specify environment:
./scripts/build-android-bundle.sh dev
```

### Using Flutter Commands Directly

```bash
# Dev Debug
flutter build apk --debug --flavor dev --dart-define=ENVIRONMENT=dev

# Dev Release
flutter build apk --release --flavor dev --dart-define=ENVIRONMENT=dev

# Prod Debug
flutter build apk --debug --flavor prod --dart-define=ENVIRONMENT=production

# Prod Release
flutter build apk --release --flavor prod --dart-define=ENVIRONMENT=production
```

### Building App Bundles (for Play Store)

```bash
# Dev
flutter build appbundle --release --flavor dev --dart-define=ENVIRONMENT=dev

# Prod
flutter build appbundle --release --flavor prod --dart-define=ENVIRONMENT=production
```

## Running on Device/Emulator

### From Android Studio

1. Select your build variant in the Build Variants panel
2. Select your device from the device dropdown
3. Click the green play button

### From Command Line

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

## File Structure

```
android/app/src/
├── main/
│   ├── AndroidManifest.xml          # Base manifest
│   ├── kotlin/
│   └── res/
├── debug/
│   └── AndroidManifest.xml          # Debug-specific settings
├── dev/
│   ├── AndroidManifest.xml          # Dev flavor settings
│   └── google-services.json         # Dev Firebase config
└── prod/
    ├── AndroidManifest.xml          # Prod flavor settings
    └── google-services.json         # Prod Firebase config
```

## Firebase Configuration

Each flavor uses its own Firebase configuration:

- **dev**: `android/app/src/dev/google-services.json` → maypole-flutter-dev
- **prod**: `android/app/src/prod/google-services.json` → maypole-flutter-ce6c3

The correct configuration is automatically selected based on the build variant.

## Comparison with iOS

| Aspect | iOS (Xcode) | Android (Gradle) |
|--------|-------------|------------------|
| Environment configs | Build Configurations | Product Flavors |
| Debug/Release modes | Build Configurations | Build Types |
| Number of configs | 4 explicit + Profile | 4 variants (2×2 matrix) |
| Config names | dev-debug, dev-release, etc. | devDebug, devRelease, etc. |
| Scheme selection | Xcode UI | Build Variants panel |
| App ID dev | app.maypole.maypole.dev | app.maypole.maypole.dev.debug |
| App ID prod | app.maypole.maypole | app.maypole.maypole |

## Environment Switching

### Quick Switch Scripts

```bash
# Switch to development
./scripts/switch-to-dev.sh

# Switch to production
./scripts/switch-to-prod.sh
```

These scripts update your `env.local` file to use the correct environment variables.

## Troubleshooting

### Build variant not showing

1. Run `flutter clean`
2. Run `flutter pub get`
3. Click `File → Sync Project with Gradle Files` in Android Studio

### Wrong Firebase project

1. Check the `google-services.json` file in the correct flavor directory
2. Verify the `ENVIRONMENT` variable in your run configuration
3. Clean and rebuild the project

### Application ID conflicts

If you see "App not installed" errors when switching between dev and prod:

1. Uninstall the existing app from the device
2. Install the new build variant

The different application IDs allow dev and prod versions to coexist on the same device.

## Best Practices

1. **Development**: Use `dev-debug` for daily development
2. **Testing**: Use `dev-release` to test performance optimizations
3. **Staging**: Use `prod-debug` to test production environment with debugging
4. **Production**: Use `prod-release` for Play Store releases

## Next Steps

- [ ] Configure proper signing for release builds (see `android/app/build.gradle.kts`)
- [ ] Set up ProGuard rules if needed
- [ ] Configure release signing in `android/key.properties`
- [ ] Test all four variants on physical devices

## Additional Resources

- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [Android Build Variants](https://developer.android.com/build/build-variants)
- [Product Flavors Guide](https://developer.android.com/studio/build/build-variants#product-flavors)
