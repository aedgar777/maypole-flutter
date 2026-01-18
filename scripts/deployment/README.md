# Deployment Scripts

This directory contains consolidated deployment scripts for building and deploying the Maypole app to various platforms and environments.

## 📚 Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference for common deployments
- **[SETUP.md](SETUP.md)** - Detailed setup guide for first-time configuration
- **[ANDROID_SETUP.md](ANDROID_SETUP.md)** - Android-specific setup (Play Store, Fastlane, signing)
- **[GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)** - How GitHub Actions CI/CD works
- **[VERSIONING.md](VERSIONING.md)** - Complete versioning strategy and automatic version bumping
- **[../ANDROID_TOOLCHAIN_FIX.md](../ANDROID_TOOLCHAIN_FIX.md)** - Fix Android toolchain issues
- **This file** - Complete deployment documentation

## 🎯 Quick Start

```bash
# Deploy everything to dev/internal testing (with tests)
./scripts/deployment/dev-deploy-all.sh

# Deploy everything to beta/public testing
./scripts/deployment/beta-deploy-all.sh

# Deploy individual platforms (dev - no version bump)
./scripts/deployment/dev-deploy-android.sh  # Android only
./scripts/deployment/dev-deploy-ios.sh      # iOS only
./scripts/deployment/dev-deploy-web.sh      # Web only

# Deploy individual platforms (beta - no version bump)
./scripts/deployment/beta-deploy-android.sh  # Android only
./scripts/deployment/beta-deploy-ios.sh      # iOS only
./scripts/deployment/beta-deploy-web.sh      # Web only
```

---

## Prerequisites

### Android
- **Android toolchain fixed**: Run `./scripts/fix-android-toolchain.sh` (required!)
- Google Play Console service account JSON key set as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` environment variable
- Android keystore configured in `android/key.properties`
- Fastlane installed: `cd android && bundle install`
- **See [ANDROID_SETUP.md](ANDROID_SETUP.md) for complete Android setup guide**

### iOS
- App Store Connect API key configured in environment variables:
  - `APP_STORE_CONNECT_API_KEY_KEY_ID`
  - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY_FILEPATH`
- Apple Developer certificates synced via Match
- Fastlane installed: `cd ios && bundle install`

### Firebase/Web
- Firebase CLI installed and authenticated: `firebase login`
- Access to both Firebase projects:
  - `maypole-flutter-dev` (development)
  - `maypole-flutter-ce6c3` (production)

## Development Environment

### Individual Deployments

#### Android (Play Store Internal Testing)
```bash
./scripts/deployment/dev-deploy-android.sh
```
Builds dev release AAB and uploads to Play Store Internal Testing track.

#### iOS (TestFlight Internal Testing)
```bash
./scripts/deployment/dev-deploy-ios.sh
```
Builds dev release IPA and uploads to TestFlight Internal Testing.

#### Web (Firebase Hosting)
```bash
./scripts/deployment/dev-deploy-web.sh
```
Builds and deploys web app to Firebase Hosting (maypole-flutter-dev).

### Full Deployment
```bash
./scripts/deployment/dev-deploy-all.sh
```
Runs all development deployments in sequence:
1. **Runs unit tests** (exits if tests fail)
2. Deploys Firebase tools (Firestore rules, indexes, storage rules, functions) to dev
3. Builds and deploys Android to Play Store Internal Testing
4. Builds and deploys iOS to TestFlight Internal Testing
5. Builds and deploys Web to Firebase Hosting

## Beta Environment

Beta builds use **production configuration** but deploy to beta testing tracks.

### Full Deployment
```bash
./scripts/deployment/beta-deploy-all.sh
```
Deploys all beta builds in sequence:
1. **Bumps patch version** (e.g., `1.0.0+20` → `1.0.1+21`)
2. Builds and uploads Android to Play Store Open Testing (beta) track
3. Builds and uploads iOS to TestFlight Beta Testing (external)
4. Builds and deploys Web to Firebase Hosting beta channel

### Individual Deployments (No Version Bump)

#### Android (Play Store Open Testing)
```bash
./scripts/deployment/beta-deploy-android.sh
```
Builds prod release AAB and uploads to Play Store Open Testing (beta) track.

#### iOS (TestFlight Beta Testing)
```bash
./scripts/deployment/beta-deploy-ios.sh
```
Builds prod release IPA and uploads to TestFlight Beta Testing with external distribution.

#### Web (Firebase Hosting Beta Channel)
```bash
./scripts/deployment/beta-deploy-web.sh
```
Builds prod web app and deploys to Firebase Hosting beta channel.

## Production Environment

### Firebase Tools
```bash
./scripts/deployment/prod-deploy-firebase.sh
```
Deploys all Firebase tools (Firestore rules, indexes, storage rules, functions) to production (maypole-flutter-ce6c3).

### Web
```bash
./scripts/deployment/prod-deploy-web.sh
```
Builds and deploys production web app to Firebase Hosting (maypole-flutter-ce6c3).

### Mobile Apps
Production mobile apps are **promoted from beta** via:
- **Android**: Play Console UI (or `fastlane promote_to_production`)
- **iOS**: App Store Connect UI

This approach ensures production releases are properly tested in beta first.

## Environment Variables

All scripts load environment variables from `.env` in the project root. Required variables:
- Firebase configuration (dev and prod)
- Google Places API keys
- App Store Connect API credentials
- Google Play service account key

See `.env` for the complete list of required environment variables.

## Deployment Tracks Overview

| Environment | Android Track | iOS Track | Web Hosting |
|-------------|---------------|-----------|-------------|
| **Dev** | Internal Testing | Internal Testing | maypole-flutter-dev |
| **Beta** | Open Testing (beta) | Beta Testing (external) | maypole-flutter-ce6c3 (beta channel) |
| **Prod** | Production* | Production* | maypole-flutter-ce6c3 |

\* Production mobile apps are promoted from beta via console UIs

## 🔄 Deployment Workflow

```
Development Cycle:
  dev-deploy-all.sh
  ├── Run unit tests (exit if fail)
  ├── Bump build number (1.0.0+20 → 1.0.0+21)
  ├── Deploy Firebase tools → maypole-flutter-dev
  ├── Build & upload Android → Internal Testing (no version bump)
  ├── Build & upload iOS → Internal Testing (no version bump)
  └── Build & deploy Web → Firebase Hosting (no version bump)

Beta Release:
  beta-deploy-all.sh
  ├── Bump patch version (1.0.0+21 → 1.0.1+22)
  ├── Build & upload Android → Open Testing (no version bump)
  ├── Build & upload iOS → TestFlight Beta (no version bump)
  └── Build & deploy Web → Beta channel (no version bump)

Production Release:
  ├── prod-deploy-firebase.sh → maypole-flutter-ce6c3
  ├── prod-deploy-web.sh → Production hosting
  └── Promote mobile apps via console UIs
      ├── Play Console: beta → production (same version)
      └── App Store Connect: beta → production (same version)
```

## Automatic Versioning

**Version bumping only happens in the `*-deploy-all.sh` scripts:**

### Development Full Deployment (`dev-deploy-all.sh`)
- **Build number only** is incremented (e.g., `1.0.0+20` → `1.0.0+21`)
- Used for frequent internal testing releases
- Individual `dev-deploy-*.sh` scripts do NOT bump versions

### Beta Full Deployment (`beta-deploy-all.sh`)
- **Patch version** is incremented (e.g., `1.0.0+20` → `1.0.1+21`)
- Build number also increments
- Used for public beta releases (more significant than dev)
- Individual `beta-deploy-*.sh` scripts do NOT bump versions

### Production Deployments
- **No auto-versioning** (mobile apps promoted from beta with same version)
- Manual version bumps for major/minor releases via `scripts/bump-version.sh`
- Scripts: `prod-deploy-*.sh`

### Individual Platform Scripts
- `dev-deploy-android.sh`, `dev-deploy-ios.sh`, `dev-deploy-web.sh` - **No version bump**
- `beta-deploy-android.sh`, `beta-deploy-ios.sh`, `beta-deploy-web.sh` - **No version bump**
- Use these when you've already bumped the version or want manual control

### Manual Version Control
```bash
# Interactive version bump (with git commit/tag options)
./scripts/bump-version.sh [major|minor|patch|build]

# Non-interactive version bump (for scripts)
./scripts/auto-bump-version.sh [major|minor|patch|build]

# Build number only (used by dev scripts)
./scripts/auto-bump-build.sh
```

## Notes

- All scripts use `set -e` to exit on any error
- Flutter builds use `--release` mode for all deployments
- Dev builds use `dev` flavor and `ENVIRONMENT=dev`
- Beta and prod builds use `prod` flavor and `ENVIRONMENT=production`
- Unit tests must pass before `dev-deploy-all.sh` proceeds with deployments
- Version bumps happen **before** building to ensure all builds have the new version
