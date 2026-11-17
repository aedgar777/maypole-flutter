# GitHub Actions Workflows

This directory contains CI/CD workflows for automated deployment of the Maypole app.

## Workflows Overview

### 🔧 `develop.yml` - Development Deployment

**Triggers**: Push to `develop` branch

**Flow**:
1. **Test & Version Bump**
   - Runs unit tests (fails deployment if tests fail)
   - Auto-bumps build number (`1.0.0+20` → `1.0.0+21`)
   - Commits and pushes version bump

2. **Deploy Firebase Tools** (parallel with mobile/web)
   - Firestore rules, indexes
   - Storage rules
   - Cloud Functions
   - To: `maypole-flutter-dev` project

3. **Build & Deploy Android** (parallel)
   - Builds dev flavor AAB
   - Uses Fastlane to upload to Play Store Internal Testing

4. **Build & Deploy iOS** (parallel)
   - Builds dev IPA
   - Uses Fastlane to upload to TestFlight Internal Testing

5. **Build & Deploy Web** (parallel)
   - Builds web app with dev config
   - Deploys to Firebase Hosting (dev)

---

### 🧪 `beta.yml` - Beta Deployment

**Triggers**: Push to `beta` branch

**Flow**:
1. **Version Bump**
   - Auto-bumps build number only (`1.3.0+20` → `1.3.0+21`)
   - The version name is set on `develop` and carried through unchanged
   - Commits and pushes version bump

2. **Build & Deploy Android** (parallel)
   - Builds prod flavor AAB (with prod Firebase config)
   - Uses Fastlane to upload to Play Store Open Testing (beta track)

3. **Build & Deploy iOS** (parallel)
   - Builds prod IPA (with prod Firebase config)
   - Uses Fastlane to upload to TestFlight Beta (external distribution)

4. **Build & Deploy Web** (parallel)
   - Builds web app with prod config
   - Deploys to Firebase Hosting beta channel

---

### 🌟 `production.yml` - Production Deployment

**Triggers**: Push to `master` or `main` branch

**Flow**:
1. **Deploy Firebase Tools**
   - Firestore rules, indexes
   - Storage rules
   - Cloud Functions
   - To: `maypole-flutter-ce6c3` project

2. **Build & Deploy Web**
   - Builds production web app
   - Deploys to Firebase Hosting (production)

**Note**: Mobile apps (Android & iOS) are **NOT** built in production workflow. They are promoted from beta through:
- **Android**: Play Console UI (beta → production)
- **iOS**: App Store Connect UI (beta → production)

This ensures the exact tested beta builds go to production.

---

## Versioning Strategy

| Workflow | Version Bump | Example |
|----------|-------------|---------|
| **Development** | Build number only | `1.0.0+20` → `1.0.0+21` |
| **Beta** | Build number only | `1.3.0+20` → `1.3.0+21` |
| **Production** | None (promotes from beta) | `1.0.1+21` → `1.0.1+21` |

Version bumps happen **before** building to ensure all platforms use the same version.

The version *name* (`MAJOR.MINOR.PATCH`) is owned by `develop`: bump it there when a
release warrants it, and beta will carry that name through, incrementing only the
build number for each beta build.

---

## Environment Secrets

All workflows require secrets configured in GitHub Actions:

### Firebase
- `FIREBASE_DEV_*` - Development Firebase configuration
- `FIREBASE_PROD_*` - Production Firebase configuration
- `MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV` - Service account for dev project
- `MAYPOLE_FIREBASE_SERVICE_ACCOUNT` - Service account for prod project

### Android
- `GOOGLE_SERVICES_JSON_DEV` - Dev google-services.json
- `GOOGLE_SERVICES_JSON_PROD` - Prod google-services.json
- `ANDROID_KEYSTORE_BASE64` - Base64-encoded keystore file
- `ANDROID_STORE_PASSWORD` - Keystore password
- `ANDROID_KEY_PASSWORD` - Key password
- `ANDROID_KEY_ALIAS` - Key alias
- `PLAY_STORE_SERVICE_ACCOUNT_JSON` - Play Store upload credentials

### iOS
- `GOOGLE_SERVICE_INFO_PLIST_DEV` - Dev GoogleService-Info.plist
- `GOOGLE_SERVICE_INFO_PLIST_PROD` - Prod GoogleService-Info.plist
- `APPLE_ID` - Apple Developer account email
- `APPLE_TEAM_ID` - Apple Team ID
- `APP_STORE_CONNECT_API_KEY_ID` - API key ID
- `APP_STORE_CONNECT_API_ISSUER_ID` - API issuer ID
- `APP_STORE_CONNECT_API_KEY_CONTENT` - .p8 file content
- `GCP_SERVICE_ACCOUNT_KEY` - For Match certificate storage
- `MATCH_GCS_BUCKET` - GCS bucket for certificates
- `MATCH_GCS_PROJECT_ID` - GCP project ID
- `MATCH_PASSWORD` - Match password

### General
- `IOS_BUNDLE_ID` - iOS bundle identifier
- `GITHUB_TOKEN` - Auto-provided by GitHub

---

## Key Differences from Deployment Scripts

### Advantages of Workflows
- **Automatic on push** - No manual script execution
- **Parallel jobs** - Faster deployment (Android, iOS, Web run simultaneously)
- **Version control** - Automatic git commits for version bumps
- **No local setup needed** - Runs on GitHub-hosted runners

### When to Use Scripts vs Workflows
- **Use workflows**: Regular releases triggered by git push
- **Use scripts**: 
  - Manual deployments
  - Local testing
  - Emergency hotfixes
  - Single-platform updates

---

## Workflow Execution

### Development Flow
```bash
git checkout develop
# Make changes
git commit -am "feat: new feature"
git push origin develop
# → Triggers develop.yml workflow
# → Version bumped, tests run, all platforms deployed
```

### Beta Release Flow
```bash
git checkout beta
git merge develop
git push origin beta
# → Triggers beta.yml workflow
# → Patch version bumped, prod builds deployed to beta tracks
```

### Production Release Flow
```bash
git checkout main
git merge beta
git push origin main
# → Triggers production.yml workflow
# → Firebase tools and web deployed

# Then manually in consoles:
# - Play Console: Promote beta → production
# - App Store Connect: Promote beta → production
```

---

## Monitoring & Debugging

### View Workflow Runs
1. Go to repository → Actions tab
2. Click on workflow run
3. View logs for each job

### Common Issues

**Version bump conflicts**
- If multiple pushes happen quickly, git push may fail
- Workflow retries 3 times with rebase
- Check Actions logs for details

**Build failures**
- Check job logs for specific error
- Verify all secrets are set correctly
- Ensure Flutter version matches project requirements

**Fastlane errors**
- Check credentials are valid
- Verify service accounts have correct permissions
- Look for timeout issues (workflows have 60min limit)

---

## Local Testing

To test workflow changes locally, you can simulate the workflow using:

```bash
# Test version bump
./scripts/auto-bump-build.sh  # or auto-bump-version.sh patch

# Test builds
flutter build appbundle --release --flavor dev
flutter build ipa --release --dart-define=ENVIRONMENT=dev
flutter build web --release --dart-define=ENVIRONMENT=dev

# Test Fastlane lanes
cd android && bundle exec fastlane deploy_dev_internal
cd ios && bundle exec fastlane ios deploy_dev
```

Or use the deployment scripts which mirror the workflow logic:
```bash
./scripts/deployment/dev-deploy-all.sh
./scripts/deployment/beta-deploy-all.sh
```

---

## Updating Flutter Version

When updating Flutter version across all workflows:

1. Update in all three workflow files:
   - `develop.yml`
   - `beta.yml`
   - `production.yml`

2. Search for `flutter-version:` and update all occurrences

3. Test locally first:
   ```bash
   flutter upgrade
   flutter test
   flutter build appbundle --release --flavor dev
   ```

4. Commit and push to trigger workflows
