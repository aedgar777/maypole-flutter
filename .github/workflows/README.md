# GitHub Actions Workflows

This directory contains automated deployment workflows for the Maypole Flutter application across three environments.

## Workflow Overview

### 1. **develop.yml** - Development Environment
**Triggers**: Pushes to `develop` branch

**Actions**:
- ✅ Runs unit tests
- 🌐 Builds and deploys web app to Firebase Hosting (dev)
- 📱 Builds `devRelease` Android app → Play Store Internal Testing
- 🍎 Builds `devRelease` iOS app → TestFlight Internal Testing
- 🔥 Deploys Firestore indexes to `maypole-flutter-dev`

**Purpose**: Continuous integration for active development. Every merge to develop triggers full testing and deployment to internal testing groups.

---

### 2. **beta.yml** - Beta Testing Environment
**Triggers**: Pushes to `beta` branch

**Actions**:
- 📱 Builds `prodRelease` Android app → Play Store Beta Track
- 🍎 Builds `prodRelease` iOS app → TestFlight Beta Group

**Purpose**: Pre-release testing with a wider audience. No tests, web deployment, or Firebase changes - just mobile app builds for beta testers.

**Note**: This workflow does NOT run tests (they should have passed in develop) and does NOT deploy Firebase services (those are production-only).

---

### 3. **production.yml** - Production Environment
**Triggers**: Pushes to `master` or `main` branch

**Actions**:
- 🌐 Builds and deploys web app to Firebase Hosting (production)
- 📱 Builds `prodRelease` Android app → Play Store Production Track
- 🍎 Builds `prodRelease` iOS app → App Store
- 🔥 Deploys ALL Firebase services to `maypole-flutter`:
  - Firestore indexes
  - Firestore rules
  - Storage rules

**Purpose**: Live production deployment. This makes your app available to all users.

---

## Branch Strategy

```
feature branches
      ↓
   develop  ← Daily development (auto-deploy to internal testing)
      ↓
    beta   ← Pre-release testing (auto-deploy to beta testers)
      ↓
   master  ← Production releases (auto-deploy to production)
```

### Workflow Process

1. **Development**: 
   - Create feature branches from `develop`
   - Merge PRs into `develop`
   - Automatic testing and deployment to internal testing

2. **Beta Release**:
   - Merge `develop` → `beta` when ready for beta testing
   - Automatic deployment to beta testing tracks

3. **Production Release**:
   - Merge `beta` → `master` when stable
   - Automatic deployment to production

---

## Build Variants

The app uses Android flavor dimensions and iOS schemes:

### Android
- **devDebug**: Development debug build
- **devRelease**: Development release build (used in develop.yml)
- **prodDebug**: Production debug build
- **prodRelease**: Production release build (used in beta.yml and production.yml)

### iOS
- **dev**: Development builds (used in develop.yml)
- **prod**: Production builds (used in beta.yml and production.yml)

---

## Required GitHub Secrets

See `DEPLOYMENT_SETUP.md` in the project root for detailed setup instructions.

### Android Secrets
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`
- `GOOGLE_SERVICES_JSON_DEV`
- `GOOGLE_SERVICES_JSON_PROD`

### iOS Secrets
- `IOS_CERTIFICATE_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT`
- `GOOGLE_SERVICE_INFO_PLIST_DEV`
- `GOOGLE_SERVICE_INFO_PLIST_PROD`

### Firebase Secrets
- `FIREBASE_DEV_*` (all Firebase dev config)
- `FIREBASE_PROD_*` (all Firebase prod config)
- `MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV`
- `MAYPOLE_FIREBASE_SERVICE_ACCOUNT`

---

## Monitoring Deployments

### GitHub Actions
View workflow runs: Repository → Actions tab

### Play Console
- **Internal Testing**: Play Console → Testing → Internal testing
- **Beta**: Play Console → Testing → Closed testing → Beta
- **Production**: Play Console → Production

### App Store Connect
- **TestFlight Internal**: App Store Connect → TestFlight → Internal Testing
- **TestFlight Beta**: App Store Connect → TestFlight → External Testing
- **Production**: App Store Connect → App Store

### Firebase
- **Dev Hosting**: `maypole-flutter-dev.web.app`
- **Production Hosting**: `maypole-flutter.web.app` (or your configured domain)

---

## Troubleshooting

### Workflow Fails on Test Job
- Check test output in GitHub Actions logs
- Run `flutter test` locally to reproduce
- Fix tests before merging

### Android Build Fails
- Verify keystore secrets are correctly set
- Check `android/key.properties` is being created correctly
- Ensure `google-services.json` is valid

### iOS Build Fails
- Verify certificate hasn't expired
- Check provisioning profile matches bundle ID
- Ensure keychain operations completed successfully

### Deploy to Store Fails
- **Play Store**: Check service account permissions in Play Console
- **App Store**: Verify API key has correct permissions in App Store Connect
- Check that app version is incremented properly

---

## Manual Overrides

### Skip Deployment to Stores
Temporarily comment out the deploy steps in the workflow files.

### Deploy Only Specific Platform
Comment out the unwanted build job in the workflow file.

### Test Workflow Without Deploying
1. Create a test branch that doesn't match the trigger pattern
2. Modify workflow to trigger on that branch
3. Push and observe results
4. Delete test branch when done

---

## Maintenance

### Regular Updates
- Update Flutter version in workflows as project requirements change
- Keep GitHub Actions versions up to date (e.g., `actions/checkout@v3` → `v4`)
- Renew iOS certificates and provisioning profiles annually
- Review and update store screenshots/metadata regularly

### Version Management
App version is defined in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- First part (1.0.0): Version name
- Second part (+1): Build number

Increment appropriately before production releases.

---

## Additional Resources

- [DEPLOYMENT_SETUP.md](DEPLOYMENT_SETUP.md) - Complete setup guide
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Play Store Publishing](https://developer.android.com/studio/publish)
- [App Store Distribution](https://developer.apple.com/app-store/distribution/)
