# Android Studio Environment Switching Guide

This guide explains how to easily switch between development and production Firebase environments
using Android Studio's GUI.

## Overview

Your Flutter app now supports multiple environments:

- **Development**: Uses `maypole-flutter-dev` Firebase project
- **Production**: Uses `maypole-flutter-ce6c3` Firebase project

## Quick Setup

### 1. Environment Files

- Copy `.env.local.example` to `env.local` (already done)
- Fill in your actual Firebase credentials in `env.local`

### 2. Android Studio Run Configurations

Four pre-configured run configurations are available:

| Configuration | Environment | Build Mode | Firebase Project |
|---------------|-------------|------------|------------------|
| `maypole (dev)` | Development | Debug | maypole-flutter-dev |
| `maypole (production)` | Production | Debug | maypole-flutter-ce6c3 |
| `maypole (dev-release)` | Development | Release | maypole-flutter-dev |
| `maypole (prod-release)` | Production | Release | maypole-flutter-ce6c3 |

## How to Switch Environments in Android Studio

### Method 1: Using Run Configurations (Recommended)

1. **Open Android Studio**
2. **Look for the run configuration dropdown** (usually shows "main.dart" by default)
    - It's located in the toolbar next to the green play button
3. **Click the dropdown** and select your desired environment:
    - `maypole (dev)` - for development testing
    - `maypole (production)` - for production testing
    - `maypole (dev-release)` - for development release builds
    - `maypole (prod-release)` - for production release builds
4. **Click the green play button** to run the app

### Method 2: Using Scripts (Terminal)

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

- **Development**: "Maypole (Dev)"
- **Production**: "Maypole"

### Console Output

When the app starts, you'll see debug information:

```
🔧 Environment Debug Info:
  • Dart Define ENVIRONMENT: "dev"
  • .env ENVIRONMENT: "dev"  
  • Final Environment: "dev"
  • Firebase Project: maypole-flutter-dev
```

## Platform-Specific Configurations

### Android

- **Development**: Uses `android/app/src/dev/google-services.json`
- **Production**: Uses `android/app/src/prod/google-services.json`
- **App Name**:
    - Dev: "Maypole Dev"
    - Prod: "Maypole"

### iOS

- Currently uses dynamic configuration via environment variables
- Future enhancement: Separate GoogleService-Info.plist files per environment

## Troubleshooting

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
3. Ensure you're using the correct run configuration

### Firebase Connection Issues

1. Verify `google-services.json` files exist in:
    - `android/app/src/dev/google-services.json`
    - `android/app/src/prod/google-services.json`
2. Check that Firebase project IDs in `env.local` are correct
3. Ensure Flutter clean was run: `flutter clean && flutter pub get`

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
flutter build apk --dart-define=ENVIRONMENT=production --flavor prod
flutter build ios --dart-define=ENVIRONMENT=production --flavor prod
```

## VS Code Support

VS Code users can use the launch configurations in `.vscode/launch.json`:

1. Open Command Palette (`Cmd+Shift+P`)
2. Type "Flutter: Select Device"
3. Use "Run and Debug" panel with available configurations

---

**Need Help?** Check the console output for environment debug information and verify your
`env.local` file is properly configured.