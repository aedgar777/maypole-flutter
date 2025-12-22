# Deployment Setup Checklist

Use this checklist to track your progress in setting up the automated deployment pipeline.

## Deployment Strategy Overview

Your CI/CD pipeline follows a three-tier deployment strategy:

### **Branch → Environment → Destination**

| Branch | Build Config | Android Track | Release Status | Purpose |
|--------|-------------|---------------|----------------|---------|
| `develop` | dev-release | Internal Testing | Auto-release (`status: completed`) | Internal testing with dev Firebase |
| `beta` | prod-release | Beta Track (Open Testing) | Auto-release (`status: completed`) | Public beta testing with prod Firebase |
| `master` | prod-release | Production Track | **Draft** (`status: draft`) | Production - **requires manual publish** |

### **Why Draft for Production?**

When you merge `beta` → `master`, the workflow uploads the AAB to the Play Console as a **draft release**. This means:

✅ **AAB is uploaded and ready** - The build is in the Play Console  
✅ **Store listing editable** - You can update descriptions, screenshots, etc.  
✅ **Release notes editable** - Polish your what's new section  
✅ **Staged rollout option** - Start with 5-10% of users and gradually increase  
✅ **Full control** - Choose exactly when to publish to millions of users  
❌ **Not live yet** - You must manually click "Publish" in the Play Console  

**To publish:**
1. Go to Play Console → Your App → Production track
2. Review the draft release
3. Optionally set up a staged rollout (recommended: start at 5-10%)
4. Click "Start rollout to Production" when ready

---

## Pre-requisites

- [] Apple Developer Program membership is approved ($99/year)
- [X] Google Play Developer account is active ($25 one-time)
- [X] Firebase projects exist: `maypole-flutter-dev` and `maypole-flutter`

---

## Android Setup

### Upload Keystore (for Google Play App Signing)
- [X] Generate upload keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [X] Save keystore passwords securely
- [X] Convert keystore to base64: `base64 -i upload-keystore.jks | tr -d '\n' > keystore_base64.txt`
- [X] Verify `android/app/build.gradle.kts` has signing config (✅ Already done)
- [X] Test local signing works: `flutter build appbundle --release --flavor prod`

### Play Console Setup
- [X] Create app in Play Console (or navigate to existing app)
- [X] Navigate to **Setup** → **App signing**
- [X] Choose to let Google create and manage your app signing key
- [X] Build and manually upload your first AAB to enable Play App Signing
- [X] Download and save your app signing certificate (for reference)
- [X] Create internal testing track and add test users
- [X] Create closed testing track (beta) and add beta testers
- [X] Verify production track is accessible

### Service Account for API Access
- [ ] Create service account in Google Cloud Console
- [ ] Download service account JSON key
- [ ] Link service account in Play Console (**Setup** → **API access**)
- [ ] Grant permissions: "View app info", "Release to testing tracks", "Release to production"
- [ ] Verify service account has access to your app

### GitHub Secrets - Android
- [ ] Add `ANDROID_KEYSTORE_BASE64` (content of keystore_base64.txt)
- [ ] Add `ANDROID_KEY_ALIAS` (typically "upload")
- [ ] Add `ANDROID_KEY_PASSWORD` (your key password)
- [ ] Add `ANDROID_STORE_PASSWORD` (your keystore password)
- [ ] Add `PLAY_STORE_SERVICE_ACCOUNT_JSON` (service account JSON content)
- [ ] Add `GOOGLE_SERVICES_JSON_DEV` (dev flavor google-services.json content)
- [ ] Add `GOOGLE_SERVICES_JSON_PROD` (prod flavor google-services.json content)

---

## iOS Setup

### Apple Developer Portal
- [ ] Create App ID with bundle identifier `app.maypole.maypole`
- [ ] Enable required capabilities (Push Notifications, etc.)
- [ ] Generate distribution certificate (.p12)
- [ ] Create App Store provisioning profile
- [ ] Download provisioning profile (.mobileprovision)

### App Store Connect
- [ ] Create app in App Store Connect
- [ ] Set up TestFlight internal testing group
- [ ] Set up TestFlight external beta testing group
- [ ] Generate App Store Connect API key (.p8)
- [ ] Save API Key ID and Issuer ID

### ExportOptions Configuration
- [ ] Update `ios/ExportOptions.plist` with your Team ID
- [ ] Update `ios/ExportOptions.plist` with provisioning profile name
- [ ] Update bundle IDs if different from `app.maypole.maypole`

### Convert Files to Base64
- [ ] Convert certificate.p12 to base64
- [ ] Convert provisioning profile to base64
- [ ] Convert API key .p8 to base64

### GitHub Secrets - iOS
- [ ] Add `IOS_CERTIFICATE_BASE64`
- [ ] Add `IOS_CERTIFICATE_PASSWORD`
- [ ] Add `IOS_PROVISIONING_PROFILE_BASE64`
- [ ] Add `KEYCHAIN_PASSWORD` (generate a secure random password)
- [ ] Add `APP_STORE_CONNECT_API_KEY_ID`
- [ ] Add `APP_STORE_CONNECT_API_ISSUER_ID`
- [ ] Add `APP_STORE_CONNECT_API_KEY_CONTENT`
- [ ] Add `GOOGLE_SERVICE_INFO_PLIST_DEV`
- [ ] Add `GOOGLE_SERVICE_INFO_PLIST_PROD`

---

## GitHub Repository Setup

### Branch Protection
- [ ] Create `beta` branch: `git checkout -b beta && git push -u origin beta`
- [ ] Configure branch protection for `beta` (require PR reviews)
- [ ] Configure branch protection for `master`/`main` (require PR reviews)

### GitHub Secrets - Firebase (verify existing)
- [ ] Verify `FIREBASE_DEV_WEB_API_KEY` exists
- [ ] Verify `FIREBASE_DEV_WEB_APP_ID` exists
- [ ] Verify `FIREBASE_DEV_WEB_MEASUREMENT_ID` exists
- [ ] Verify `FIREBASE_DEV_ANDROID_API_KEY` exists
- [ ] Verify `FIREBASE_DEV_ANDROID_APP_ID` exists
- [ ] Verify `FIREBASE_DEV_IOS_API_KEY` exists
- [ ] Verify `FIREBASE_DEV_IOS_APP_ID` exists
- [ ] Verify `FIREBASE_DEV_MESSAGING_SENDER_ID` exists
- [ ] Verify `FIREBASE_DEV_PROJECT_ID` exists
- [ ] Verify `FIREBASE_DEV_AUTH_DOMAIN` exists
- [ ] Verify `FIREBASE_DEV_STORAGE_BUCKET` exists
- [ ] Verify `FIREBASE_PROD_*` equivalents exist
- [ ] Verify `MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV` exists
- [ ] Verify `MAYPOLE_FIREBASE_SERVICE_ACCOUNT` exists
- [ ] Verify `IOS_BUNDLE_ID` exists

---

## Firebase Configuration

### Firebase Projects
- [ ] Ensure `firestore.rules` exists in project root
- [ ] Ensure `firestore.indexes.json` exists in project root
- [ ] Ensure `storage.rules` exists in project root
- [ ] Test Firebase deployment locally: `firebase deploy --project maypole-flutter-dev --only firestore:indexes`

---

## Testing Workflows

### Test Development Workflow
- [ ] Make a test commit to `develop` branch
- [ ] Watch workflow run in GitHub Actions
- [ ] Verify tests pass
- [ ] Verify web deploys to Firebase Hosting dev
- [ ] Verify Android builds and uploads to Play Store internal
- [ ] Verify iOS builds and uploads to TestFlight internal
- [ ] Check internal testing channels for new build

### Test Beta Workflow
- [ ] Merge `develop` into `beta`
- [ ] Watch workflow run in GitHub Actions
- [ ] Verify Android uploads to Play Store beta track
- [ ] Verify iOS uploads to TestFlight beta group
- [ ] Check beta testing channels for new build

### Test Production Workflow
- [ ] Merge `beta` into `master`
- [ ] Watch workflow run in GitHub Actions
- [ ] Verify web deploys to Firebase Hosting production
- [ ] Verify Firebase services deploy (rules, indexes)
- [ ] Verify Android uploads to Play Store production
- [ ] Verify iOS uploads to App Store
- [ ] Check production tracks for new build

---

## Documentation Review

- [ ] Read `DEPLOYMENT_SETUP.md` for detailed instructions
- [ ] Read `.github/workflows/README.md` for workflow details
- [ ] Understand branch strategy and release process
- [ ] Bookmark relevant Play Console and App Store Connect URLs

---

## Post-Setup Maintenance

### Regular Tasks
- [ ] Set calendar reminder to renew iOS certificates (annual)
- [ ] Set calendar reminder to renew provisioning profiles (annual)
- [ ] Document any workflow modifications in repository
- [ ] Update Flutter version in workflows when upgrading project

### Version Management
- [ ] Increment version in `pubspec.yaml` before each production release
- [ ] Follow semantic versioning: MAJOR.MINOR.PATCH+BUILD
- [ ] Keep changelog updated with release notes

---

## Troubleshooting Resources

If you encounter issues:

1. **Check GitHub Actions logs** for detailed error messages
2. **Review workflow files** for configuration issues
3. **Verify all secrets** are properly set and not expired
4. **Test locally** before pushing to remote
5. **Consult documentation**:
   - `DEPLOYMENT_SETUP.md` - Setup instructions
   - `.github/workflows/README.md` - Workflow details
   - Flutter docs: https://docs.flutter.dev/deployment/cd
   - Firebase docs: https://firebase.google.com/docs/cli
   - Play Console help: https://support.google.com/googleplay/android-developer
   - App Store Connect help: https://developer.apple.com/support/app-store-connect/

---

## Success Criteria

✅ **You're done when**:
- All checkboxes above are completed
- All three workflows run successfully
- Apps appear in the correct testing/production tracks
- Web app deploys to Firebase Hosting
- Firebase services deploy correctly
- Team can successfully test new builds

---

## Quick Reference Commands

```bash
# Create beta branch
git checkout develop
git checkout -b beta
git push -u origin beta

# Test workflow triggers
git checkout develop
git add .
git commit -m "test: trigger dev workflow"
git push origin develop

# Promote to beta
git checkout beta
git merge develop
git push origin beta

# Promote to production
git checkout master
git merge beta
git push origin master

# Base64 encode files
base64 -i file.jks | tr -d '\n' > file_base64.txt
base64 -i file.p12 | tr -d '\n' > file_base64.txt
base64 -i file.mobileprovision | tr -d '\n' > file_base64.txt

# Test local builds
flutter test
flutter build web --release --flavor dev
flutter build appbundle --release --flavor prod
flutter build ipa --release --flavor prod

# Firebase deploy test
firebase deploy --only firestore:indexes --project maypole-flutter-dev
```

---

**Note**: This is a living document. Update it as you complete tasks or as the deployment process evolves.
