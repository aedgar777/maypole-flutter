# Android Beta Deployment Guide

## Overview
This workflow automatically builds and deploys your Android app to the Google Play Store Beta track as a draft release.

## How It Works

### 1. Version Bumping (Automatic)
- The workflow automatically increments the build number on every push to the `beta` branch
- Current version: `1.0.0+11` (format: `VERSION_NAME+BUILD_NUMBER`)
- Each deployment increments the build number: `11` → `12` → `13`, etc.
- Version bumps are committed back to the `beta` branch with `[skip ci]` to prevent loops

### 2. Build Process
- Uses Flutter 3.32.0 stable
- Builds the `prodRelease` flavor with production Firebase configuration
- Creates an Android App Bundle (`.aab`) file
- Signing handled via GitHub Secrets

### 3. Draft Upload
- Uploads the `.aab` to the Play Store Beta track as a **draft release**
- **Key Behavior**: New drafts with higher version codes automatically replace older drafts
- This means you can push multiple times and only the latest draft will exist

### 4. Manual Completion Required
Because your app is in draft status in the Play Console, you need to:
1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to your app → Release → Testing → Beta
3. Click "Review Release"
4. Click "Start Rollout to Beta"

## Why Draft Status?

Google Play restricts draft apps to only accept draft releases. This is a one-time limitation until your app is fully published. Once you publish to production, you can change the workflow to use `status: completed` for fully automated deployments.

## Workflow Trigger

```yaml
on:
  push:
    branches:
      - beta
```

Push to the `beta` branch to trigger a deployment.

## Required Secrets

The following GitHub Secrets must be configured:

### Android Signing
- `ANDROID_KEYSTORE_BASE64` - Base64 encoded upload keystore
- `ANDROID_STORE_PASSWORD` - Keystore password
- `ANDROID_KEY_PASSWORD` - Key password
- `ANDROID_KEY_ALIAS` - Key alias

### Play Store Deployment
- `PLAY_STORE_SERVICE_ACCOUNT_JSON` - Service account JSON for Play Store API

### Firebase Configuration
- `GOOGLE_SERVICES_JSON_PROD` - google-services.json for production
- `FIREBASE_PROD_*` - Various Firebase config values

## Troubleshooting

### "Only releases with status draft may be created on draft app"
This error occurs if you try to use `status: completed`. For draft apps, you must use `status: draft`.

### Multiple Drafts Showing Up
This shouldn't happen - newer drafts automatically replace older ones with the same or lower version code. If you see multiple drafts, they likely have different version codes.

### Build Number Not Incrementing
Check the "Auto-Bump Build Number" step in the workflow logs. The script should show:
```
Current: 1.0.0+11
New:     1.0.0+12
```

If this fails, the commit may not be pushed back to the branch.

## Future Improvements

Once your app is published to production:
1. Change `status: draft` to `status: completed` in `.github/workflows/beta.yml`
2. Remove the manual completion step
3. Beta releases will be fully automated

## Related Files
- `.github/workflows/beta.yml` - Main workflow file
- `scripts/auto-bump-build.sh` - Version bumping script
- `scripts/get-version.sh` - Version display script
- `pubspec.yaml` - Contains the version number
