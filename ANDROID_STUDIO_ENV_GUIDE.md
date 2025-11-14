# Android Studio Environment Switching Guide

This guide explains how to easily switch between development and production Firebase environments
using Android Studio's GUI.

## Overview

Your Flutter app now supports multiple environments with four build variants that match iOS:

- **Development**: Uses `maypole-flutter-dev` Firebase project
- **Production**: Uses `maypole-flutter-ce6c3` Firebase project

### Build Variants

Android combines **Product Flavors** (dev/prod) with **Build Types** (debug/release) to create four
variants:

| Variant       | Flavor | Build Type | Application ID                | Description                |
|---------------|--------|------------|-------------------------------|----------------------------|
| `devDebug`    | dev    | debug      | app.maypole.maypole.dev.debug | Development with debugging |
| `devRelease`  | dev    | release    | app.maypole.maypole.dev       | Development optimized      |
| `prodDebug`   | prod   | debug      | app.maypole.maypole.debug     | Production with debugging  |
| `prodRelease` | prod   | release    | app.maypole.maypole           | Production optimized       |

**Note:** These match the iOS configurations: dev-debug, dev-release, prod-debug, and prod-release.

## Quick Setup

### 1. Environment Files

- Copy `.env.local.example` to `env.local` (already done)
- Fill in your actual Firebase credentials in `env.local`

### 2. Android Studio Build Variants

In Android Studio, you can switch between build variants using the **Build Variants** panel:

1. Click on `Build Variants` tab (usually on left side)
2. Select from the dropdown:
    - `devDebug` - Development with debugging (matches iOS dev-debug)
    - `devRelease` - Development release build (matches iOS dev-release)
    - `prodDebug` - Production with debugging (matches iOS prod-debug)
    - `prodRelease` - Production release build (matches iOS prod-release)

### 3. Run Configurations (Optional)

Four pre-configured run configurations are available:

| Configuration            | Build Variant | Firebase Project      |
|--------------------------|---------------|-----------------------|
| `maypole (dev)`          | devDebug      | maypole-flutter-dev   |
| `maypole (production)`   | prodDebug     | maypole-flutter-ce6c3 |
| `maypole (dev-release)`  | devRelease    | maypole-flutter-dev   |
| `maypole (prod-release)` | prodRelease   | maypole-flutter-ce6c3 |

## How to Switch Environments in Android Studio

### Method 1: Using Build Variants Panel (Recommended)

1. **Open Build Variants Panel**
    - Click on `Build Variants` tab on the left side of Android Studio
    - Or go to `View → Tool Windows → Build Variants`

2. **Select Your Build Variant**
    - Click the dropdown under "Active Build Variant"
    - Choose your desired variant (devDebug, devRelease, prodDebug, or prodRelease)

3. **Run the App**
    - Click the green play button to run on a device/emulator

### Method 2: Using Run Configurations

1. **Open Android Studio**
2. **Look for the run configuration dropdown** (usually shows "main.dart" by default)
    - It's located in the toolbar next to the green play button
3. **Click the dropdown** and select your desired environment:
    - `maypole (dev)` - for development testing (devDebug)
    - `maypole (production)` - for production testing (prodDebug)
    - `maypole (dev-release)` - for development release builds (devRelease)
    - `maypole (prod-release)` - for production release builds (prodRelease)
4. **Click the green play button** to run the app

### Method 3: Using Scripts (Terminal)

For quick environment switching:

```bash
# Switch to development
./scripts/switch-to-dev.sh

# Switch to production  
./scripts/switch-to-prod.sh
```

Then use any run configuration or run manually:

```bash
flutter run --dart-define=ENVIRONMENT=dev --flavor dev
```

## Visual Indicators

### App Title

The app title changes based on environment:

- **Development**: "Maypole Dev"
- **Production**: "Maypole"

### Application ID

Different application IDs allow dev and prod to coexist on the same device:

- **Dev Debug**: `app.maypole.maypole.dev.debug`
- **Dev Release**: `app.maypole.maypole.dev`
- **Prod Debug**: `app.maypole.maypole.debug`
- **Prod Release**: `app.maypole.maypole`

### Console Output

When the app starts, you'll see debug information:

```
🔧 Environment Debug Info:
  • Dart Define ENVIRONMENT: "dev"
  • .env ENVIRONMENT: "dev"  
  • Final Environment: "dev"
  • Firebase Project: maypole-flutter-dev
```

## Build Scripts

We've created build scripts that match the iOS workflow:

```bash
# Build APKs
./scripts/build-android-dev-debug.sh
./scripts/build-android-dev-release.sh
./scripts/build-android-prod-debug.sh
./scripts/build-android-prod-release.sh

# Build App Bundle (for Play Store)
./scripts/build-android-bundle.sh        # defaults to prod
./scripts/build-android-bundle.sh dev    # for dev
```

## Platform-Specific Configurations

### Android

- **Development**: Uses `android/app/src/dev/google-services.json`
- **Production**: Uses `android/app/src/prod/google-services.json`
- **App Name**:
    - Dev: "Maypole Dev"
    - Prod: "Maypole"
- **Build Variants**: devDebug, devRelease, prodDebug, prodRelease

### iOS

- **Build Configurations**: dev-debug, dev-release, prod-debug, prod-release
- **Bundle ID**:
    - Dev: `app.maypole.maypole.dev`
    - Prod: `app.maypole.maypole`

## Troubleshooting

### Build Variant Not Showing

1. Run `flutter clean`
2. Run `flutter pub get`
3. Click `File → Sync Project with Gradle Files` in Android Studio
4. Restart Android Studio if needed

### Configuration Not Showing

1. Restart Android Studio
2. Check that `.idea/runConfigurations/` folder exists
3. Verify the XML files are present:
    - `maypole_dev.xml`
    - `maypole_production.xml`
    - `maypole_dev_release.xml`
    - `maypole_prod_release.xml`

### Environment Not Switching

1. Check console output for "Environment Debug Info"
2. Verify `env.local` file exists and has correct `ENVIRONMENT=` value
3. Ensure you're using the correct run configuration or build variant
4. Try cleaning the project: `flutter clean && flutter pub get`

### Firebase Connection Issues

1. Verify `google-services.json` files exist in:
    - `android/app/src/dev/google-services.json`
    - `android/app/src/prod/google-services.json`
2. Check that Firebase project IDs in `env.local` are correct
3. Ensure Flutter clean was run: `flutter clean && flutter pub get`
4. Sync Gradle files: `File → Sync Project with Gradle Files`

### Application ID Conflicts

If you see "App not installed" errors:

1. Uninstall the existing app from the device
2. Install the new build variant

Different application IDs allow dev and prod versions to coexist on the same device.

## Advanced Usage

### Adding New Environments

1. Create new flavor in `android/app/build.gradle.kts`
2. Add new `google-services.json` file in appropriate directory
3. Create new run configuration in `.idea/runConfigurations/`
4. Add environment variables to `env.local`

### Command Line Usage

```bash
# Development
flutter run --dart-define=ENVIRONMENT=dev --flavor dev

# Production  
flutter run --dart-define=ENVIRONMENT=production --flavor prod

# Release builds
flutter build apk --release --flavor dev --dart-define=ENVIRONMENT=dev
flutter build apk --release --flavor prod --dart-define=ENVIRONMENT=production

# App Bundles
flutter build appbundle --release --flavor prod --dart-define=ENVIRONMENT=production
```

## VS Code Support

VS Code users can use the launch configurations in `.vscode/launch.json`:

1. Open Command Palette (`Cmd+Shift+P`)
2. Type "Flutter: Select Device"
3. Use "Run and Debug" panel with available configurations

## Additional Documentation

For more detailed information about the Android build system, see:

- **[ANDROID_BUILD_CONFIGURATIONS.md](./ANDROID_BUILD_CONFIGURATIONS.md)** - Complete guide to build
  variants
- **[ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md)** - Firebase configuration setup
- **[ENVIRONMENT_SWITCHING.md](./ENVIRONMENT_SWITCHING.md)** - Environment switching guide

---

**Need Help?** Check the console output for environment debug information and verify your
`env.local` file is properly configured.