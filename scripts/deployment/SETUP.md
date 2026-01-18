# Deployment Setup Guide

This guide helps you set up everything needed to run the deployment scripts.

## Required Environment Variables

Add these to your shell profile (`.bashrc`, `.zshrc`, etc.) or export before running scripts:

### Android Play Store
```bash
# Path to Google Play Console service account JSON key
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="/path/to/your/play-store-service-account.json"
```

**How to get this:**
1. Go to Google Play Console → Setup → API access
2. Create or use existing service account
3. Download JSON key
4. Store securely (NOT in git repo)

### iOS App Store Connect

```bash
# Apple Developer Account
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export IOS_BUNDLE_ID="app.maypole.maypole"

# App Store Connect API Key
export APP_STORE_CONNECT_API_KEY_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="/path/to/AuthKey_XXXXX.p8"

# Match (code signing)
export MATCH_PASSWORD="your-match-password"
export MATCH_GCS_BUCKET="your-certificates-bucket"
export MATCH_GCS_PROJECT_ID="your-gcp-project-id"

# GCP Service Account for Match
export GCP_SERVICE_ACCOUNT_KEY="$(cat /path/to/gcp-service-account.json)"
```

**How to get App Store Connect API Key:**
1. Go to App Store Connect → Users and Access → Keys
2. Generate new API key with Admin access
3. Download the `.p8` file
4. Note the Key ID and Issuer ID

## Android Setup

### 1. Install Fastlane
```bash
cd android
bundle install
```

### 2. Configure Keystore
Create `android/key.properties`:
```properties
storeFile=/path/to/your/keystore.jks
storePassword=your-keystore-password
keyAlias=your-key-alias
keyPassword=your-key-password
```

**Important:** Keep this file secure and never commit to git!

### 3. Test Fastlane
```bash
cd android
bundle exec fastlane --version
```

## iOS Setup

### 1. Install Fastlane
```bash
cd ios
bundle install
```

### 2. Set up Match (Code Signing)
Match stores your certificates and provisioning profiles in Google Cloud Storage.

First time setup:
```bash
cd ios
bundle exec fastlane match init
```

Sync certificates:
```bash
cd ios
bundle exec fastlane sync_dev_signing
```

### 3. Test Fastlane
```bash
cd ios
bundle exec fastlane --version
```

## Firebase Setup

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login
```bash
firebase login
```

### 3. Verify Access
```bash
firebase projects:list
```

You should see both:
- `maypole-flutter-dev`
- `maypole-flutter-ce6c3`

## Environment File

Ensure `.env` exists in project root with all required Firebase configuration. See `.env` for the template.

## Verification

Test each component:

### Android
```bash
./scripts/deployment/dev-deploy-android.sh
```

### iOS
```bash
./scripts/deployment/dev-deploy-ios.sh
```

### Web
```bash
./scripts/deployment/dev-deploy-web.sh
```

### Full Pipeline
```bash
./scripts/deployment/dev-deploy-all.sh
```

## Troubleshooting

### Android: "Service account JSON not found"
- Ensure `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` points to valid JSON file
- Check file permissions

### iOS: "Could not find App Store Connect API key"
- Verify all `APP_STORE_CONNECT_API_KEY_*` variables are set
- Check `.p8` file path is correct

### iOS: "No code signing identity found"
- Run `bundle exec fastlane sync_dev_signing` in `ios/` directory
- Ensure Match credentials are configured

### Firebase: "No project active"
- Verify `.firebaserc` exists in project root
- Run `firebase use --add` to select project

### "Permission denied"
- Make scripts executable: `chmod +x scripts/deployment/*.sh`

## Security Notes

**Never commit these files:**
- `android/key.properties`
- `*.jks` (keystore files)
- `*.p8` (App Store Connect API keys)
- `*service-account*.json` (Google Play service accounts)
- `.env.local` (if you use it for secrets)

All deployment scripts read from environment variables, so secrets stay out of git.

## CI/CD Integration

These scripts work great in CI/CD pipelines. In your CI system:

1. Store secrets as environment variables or secure files
2. Install dependencies (Flutter, Fastlane, Firebase CLI)
3. Export required environment variables
4. Run deployment scripts

Example GitHub Actions:
```yaml
- name: Deploy Android Dev
  env:
    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: ${{ secrets.PLAY_STORE_JSON }}
  run: ./scripts/deployment/dev-deploy-android.sh
```
