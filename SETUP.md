# Maypole Flutter Project Setup

This document explains how to set up the Maypole Flutter project with Firebase integration.

## Prerequisites

- Flutter SDK (latest stable version)
- Firebase CLI
- Android Studio / Xcode (for mobile development)
- A Firebase project (both development and production)

## Firebase Configuration Setup

### 1. Environment Variables

The project uses environment variables to securely manage Firebase configuration. You need to create
your own environment file:

1. Copy the example environment file:
   ```bash
   cp .env.example .env.local
   ```

2. Fill in your actual Firebase configuration values in `.env.local`:
    - Get these values from your Firebase Console → Project Settings → General
    - Each platform (Web, Android, iOS) has different configuration values

### 2. Google Services Files

#### Android Configuration

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. The file is gitignored, so it won't be committed to version control

#### iOS Configuration (when ready)

1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`
3. The file is gitignored, so it won't be committed to version control

### 3. Build Configuration

The project supports two environments:

- **Development**: Uses `maypole-flutter-dev` Firebase project
- **Production**: Uses `maypole-flutter-ce6c3` Firebase project

#### Building for Development

```bash
flutter build web --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
flutter build apk --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
```

#### Building for Production

```bash
flutter build web --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=production
flutter build apk --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=production
```

## CI/CD Setup

### GitHub Actions (Current Setup)

#### 1. Repository Secrets Setup

You need to add all your Firebase configuration values as **GitHub repository secrets**:

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Use the helper script to generate the secrets:
   ```bash
   ./scripts/generate-env-for-ci.sh github
   ```
3. Copy each secret name and value into GitHub manually

#### 2. Alternative: Use Environment Groups (Recommended)

For better organization, use GitHub Environments:

1. **Development Environment**:
    - Go to **Settings** → **Environments** → Create "development"
    - Add all `FIREBASE_DEV_*` secrets here

2. **Production Environment**:
    - Go to **Settings** → **Environments** → Create "production"
    - Add all `FIREBASE_PROD_*` secrets here

#### 3. Required Secrets Summary

- **22 Firebase configuration secrets** (API keys, app IDs, etc.)
- **2 Firebase service account secrets** (already configured)
- **1 GitHub token** (automatically provided)

### Other CI/CD Platforms

For **GitLab CI**, **Azure DevOps**, **CircleCI**, etc.:

1. Generate environment variables format:
   ```bash
   ./scripts/generate-env-for-ci.sh other
   ```
2. Add these as environment variables in your CI/CD platform
3. Update your pipeline configuration to use `--dart-define` flags

### Example GitLab CI Configuration

```yaml
# .gitlab-ci.yml
build_web:
  script:
    - flutter build web --release \
        --dart-define=ENVIRONMENT=production \
        --dart-define=FIREBASE_PROD_WEB_API_KEY="$FIREBASE_PROD_WEB_API_KEY" \
        --dart-define=FIREBASE_PROD_WEB_APP_ID="$FIREBASE_PROD_WEB_APP_ID"
        # ... add all other variables
```

## Setting Up Your Firebase Projects

### Development Project (maypole-flutter-dev)

1. Create a Firebase project named `maypole-flutter-dev`
2. Enable Authentication, Firestore, and Storage
3. Configure your platforms (Web, Android, iOS)
4. Download configuration files

### Production Project (maypole-flutter-ce6c3)

1. Create a Firebase project named `maypole-flutter-ce6c3`
2. Enable Authentication, Firestore, and Storage
3. Configure your platforms (Web, Android, iOS)
4. Download configuration files

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_DEV_WEB_API_KEY` | Development web API key | `AIzaSy...` |
| `FIREBASE_DEV_WEB_APP_ID` | Development web app ID | `1:123...:web:abc...` |
| `FIREBASE_DEV_ANDROID_API_KEY` | Development Android API key | `AIzaSy...` |
| `FIREBASE_DEV_ANDROID_APP_ID` | Development Android app ID | `1:123...:android:def...` |
| `FIREBASE_DEV_IOS_API_KEY` | Development iOS API key | `AIzaSy...` |
| `FIREBASE_DEV_IOS_APP_ID` | Development iOS app ID | `1:123...:ios:ghi...` |
| `FIREBASE_DEV_MESSAGING_SENDER_ID` | Development messaging sender ID | `123456789` |
| `FIREBASE_PROD_*` | Production equivalents of above | Similar format |
| `ENVIRONMENT` | Build environment (`dev` or `production`) | `dev` |

## Local Development

1. Clone the repository
2. Follow the Firebase configuration steps above
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
   ```

## Security Notes

- Never commit actual API keys or configuration files to version control
- The `.env.local` file is gitignored and should contain your actual secrets
- Template files (`.env.example`, `google-services.json.example`) show the structure without
  exposing secrets
- Firebase web API keys are not truly secret (they're exposed in the client), but Android/iOS keys
  should be protected
- Use different Firebase projects for development and production
- CI/CD secrets should be stored in your platform's secure secret management system

## Troubleshooting

### Missing Configuration

If you see errors about missing configuration:

1. Ensure `.env.local` exists and has all required values
2. Check that `google-services.json` exists in `android/app/`
3. Verify you're using the correct `--dart-define=ENVIRONMENT=` flag

### Firebase Initialization Errors

1. Double-check your Firebase project IDs match the ones in your config
2. Ensure all required services are enabled in Firebase Console
3. Verify your SHA-1 fingerprints are configured for Android

### Build Issues

1. Run `flutter clean` and `flutter pub get`
2. Check that all required files are in place
3. Ensure you're using compatible Flutter and Firebase SDK versions

### CI/CD Issues

1. Verify all secrets are properly set in your CI/CD platform
2. Check that secret names match exactly (case-sensitive)
3. Ensure your workflow/pipeline files reference the correct secret names
4. Use the `generate-env-for-ci.sh` script to verify your setup