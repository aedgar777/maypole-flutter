# iOS Fastlane Setup

This directory contains the iOS app configuration and Fastlane automation for code signing and deployment.

## Fastlane Match

This project uses **Fastlane Match** for automated iOS code signing. This means:

- ✅ **No manual certificate management** required
- ✅ **Certificates stored securely** in a private Git repository
- ✅ **CI/CD works automatically** with proper GitHub Secrets
- ✅ **Team members share the same certificates**

## Files in this Directory

- **`Gemfile`**: Ruby dependencies (Fastlane, CocoaPods)
- **`Fastfile`**: Fastlane lanes (automation scripts) for building and deploying
- **`Matchfile`**: Configuration for Fastlane Match (certificate management)
- **`Podfile`**: CocoaPods dependencies for iOS native code
- **`Runner.xcworkspace`**: Xcode workspace (open this in Xcode, not .xcodeproj)

## Getting Started

### First-Time Setup

1. **Install dependencies:**

```bash
cd ios
bundle install
pod install
```

2. **Initialize Match (one-time):**

See the detailed guide: `../.github/workflows/FASTLANE_MATCH_QUICKSTART.md`

Quick version:

```bash
export MATCH_GIT_URL="https://github.com/yourusername/maypole-ios-certificates.git"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export IOS_BUNDLE_ID="app.maypole.maypole"

bundle exec fastlane match appstore
```

### Building Locally

#### Dev Build

```bash
# From project root
flutter build ios --release --flavor dev --no-codesign

# Then sign and build with Fastlane
cd ios
bundle exec fastlane deploy_dev
```

#### Production Build

```bash
# From project root
flutter build ios --release --flavor prod --no-codesign

# Then sign and build with Fastlane
cd ios
bundle exec fastlane deploy_prod
```

## Fastlane Lanes

Available lanes in `Fastfile`:

- **`sync_dev_signing`**: Download development certificates from Match
- **`sync_prod_signing`**: Download production certificates from Match
- **`deploy_dev`**: Build and upload dev build to TestFlight Internal
- **`deploy_beta`**: Build and upload beta build to TestFlight External
- **`deploy_prod`**: Build and upload production build to TestFlight/App Store

## Common Tasks

### View Current Certificates

```bash
cd ios
bundle exec fastlane match appstore --readonly
```

### Regenerate Certificates

```bash
cd ios
bundle exec fastlane match appstore --force
```

### Nuke and Recreate (use with caution!)

```bash
cd ios
bundle exec fastlane match nuke distribution
bundle exec fastlane match appstore
```

⚠️ **Warning**: This affects all team members!

## Troubleshooting

### Build Fails with "No signing identity"

**Solution**: Run Match to download certificates:

```bash
cd ios
export MATCH_GIT_URL="..."
export APPLE_ID="..."
export APPLE_TEAM_ID="..."
export IOS_BUNDLE_ID="..."
bundle exec fastlane match appstore
```

### "Wrong passphrase" Error

**Solution**: Ensure you're using the correct `MATCH_PASSWORD` that was set during initialization.

### Pod Install Fails

**Solution**: 

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

## CI/CD (GitHub Actions)

The workflows in `../.github/workflows/` handle:

- **develop.yml**: Builds and deploys dev builds to TestFlight Internal
- **beta.yml**: Builds and deploys beta builds to TestFlight External
- **production.yml**: Builds and deploys production builds to App Store

Fastlane Match runs automatically in CI using GitHub Secrets.

## Documentation

- **Full Setup Guide**: `../.github/workflows/DEPLOYMENT_SETUP.md`
- **Quick Start**: `../.github/workflows/FASTLANE_MATCH_QUICKSTART.md`
- **Fastlane Docs**: [docs.fastlane.tools](https://docs.fastlane.tools/)
- **Match Docs**: [docs.fastlane.tools/actions/match](https://docs.fastlane.tools/actions/match/)

## Architecture

```
ios/
├── Gemfile                    # Ruby dependencies
├── Fastfile                   # Fastlane automation scripts
├── Matchfile                  # Match configuration
├── Podfile                    # CocoaPods dependencies
├── Runner.xcworkspace/        # Xcode workspace (use this!)
├── Runner.xcodeproj/          # Xcode project
├── Runner/                    # iOS app source code
│   ├── AppDelegate.swift
│   ├── Info.plist
│   └── GoogleService-Info.plist (generated in CI)
└── ExportOptions.plist        # Export settings for IPA
```

## Environment Variables

When running Fastlane locally, you'll need:

- `MATCH_GIT_URL`: Git repo for certificates
- `MATCH_PASSWORD`: Encryption passphrase
- `APPLE_ID`: Your Apple ID email
- `APPLE_TEAM_ID`: Your Apple Developer Team ID
- `IOS_BUNDLE_ID`: App bundle identifier
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`: App-specific password

In CI/CD, these are stored as GitHub Secrets.

## Support

For issues with:
- **iOS builds**: Check Xcode logs
- **Fastlane**: Check `fastlane/report.xml`
- **Match**: Check certificates repository
- **CI/CD**: Check GitHub Actions logs

Happy deploying! 🚀
