# Deployment Setup Guide

This guide will walk you through setting up automated deployments for the Maypole Flutter app across three environments: Development, Beta, and Production.

## Table of Contents

1. [Android Setup](#android-setup)
2. [iOS Setup](#ios-setup)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Beta Branch Creation](#beta-branch-creation)
5. [Firebase Configuration](#firebase-configuration)
6. [Testing the Workflows](#testing-the-workflows)

---

## Android Setup

> **📱 About Google Play App Signing**
>
> This setup uses **Google Play App Signing**, which is Google's recommended approach and provides significant security benefits:
> 
> **How it works:**
> 1. You create a simple **upload key** (easy to reset if compromised)
> 2. Google generates and securely stores the real **app signing key**
> 3. You sign your AABs with the upload key and upload to Play Console
> 4. Google re-signs with the app signing key before distributing to users
>
> **Benefits:**
> - ✅ **Lost/stolen upload key?** Just reset it in Play Console - your app signing key is safe with Google
> - ✅ **Simpler CI/CD** - Only need to manage a simple upload keystore in GitHub Secrets
> - ✅ **Better security** - Your actual app signing key never leaves Google's infrastructure
> - ✅ **Required for App Bundles** - Google Play requires App Signing for dynamic delivery features
>
> **The traditional approach** (managing your own app signing key) is more complex, riskier, and not recommended.

### 1. Create Upload Keystore

Create a simple upload keystore for signing your app bundles:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias play-store-upload
```

**Fill in the prompts**:
- **Password**: Choose a secure password (you'll need this for GitHub Secrets)
- **Name**: Your name or organization
- **Organization Unit**: Your team/department
- **Organization**: Your company name
- **City/Locality**: Your city
- **State/Province**: Your state
- **Country Code**: Your two-letter country code (e.g., US)

**Important**: Save this information securely:
- **Key alias**: `upload` (or whatever you chose)
- **Key password**: The password you set
- **Store password**: Usually the same as key password

### 2. Configure Android Build for Signing

The build configuration has already been updated in `android/app/build.gradle.kts` to support keystore signing. The workflow will create the `key.properties` file automatically during CI/CD builds.

**Local Testing** (optional): If you want to test release builds locally, create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=play-store-upload
storeFile=upload-keystore.jks
```

Then copy your keystore to `android/app/upload-keystore.jks`.

**Note**: These files are gitignored and won't be committed.

### 3. Create Service Account for Play Console API

This allows GitHub Actions to automatically upload builds to Play Console.
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Name it something like "github-actions-play-store"
6. Click **Create and Continue**
7. Grant the **Service Account User** role
8. Click **Done**
9. Click on the created service account
10. Go to **Keys** tab → **Add Key** → **Create new key**
11. Choose **JSON** format and download it
12. **Save this JSON file securely** - you'll add it to GitHub Secrets

### 4. Link Service Account to Play Console
1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to **Setup** → **API access**
3. Link your Google Cloud project if not already linked
4. Grant access to your service account:
   - Find the service account you created
   - Click **Grant access**
   - Under **App permissions**, select your app
   - Under **Account permissions**, grant:
     - **View app information and download bulk reports** (read-only)
     - **Release apps to testing tracks** (release management)
     - **Release apps to production** (release management, only if you want automated production releases)
   - Click **Apply** then **Invite user**

### 5. Set Up Play App Signing

**First Time Setup** (when creating a new app):

1. In Play Console, create your app
2. Navigate to **Setup** → **App signing**
3. Choose **Continue** to let Google create and manage your app signing key
4. Upload your first signed AAB (you'll need to do this before the automated pipeline works)

**To upload your first AAB manually**:

```bash
# Build your first AAB locally
flutter build appbundle --release --flavor prod

# Sign it with your upload key
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore upload-keystore.jks \
  build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  upload

# Upload through Play Console web UI:
# Release → Production (or Internal testing) → Create new release → Upload AAB
```

After the first upload, Google will display your app signing key certificate. The automated workflow will handle subsequent uploads.

**Important**: After setup, download the **App Signing Certificate** from Play Console:
1. Go to **Setup** → **App signing**
2. Download the **App signing certificate** (for verification purposes)
3. Keep this safe - you may need it for API integrations

### 6. Set Up Testing Tracks

1. In Play Console, go to your app
2. Navigate to **Testing** → **Internal testing**
3. Create an internal testing track if you haven't already
4. Add testers/testing groups (email addresses or Google Groups)
5. Repeat for **Closed testing** → Create **Beta** track
6. Add beta testers to the beta track

### 7. Prepare Keystore for GitHub

Convert your upload keystore to base64:

```bash
base64 -i upload-keystore.jks | tr -d '\n' > keystore_base64.txt
```

The content of `keystore_base64.txt` will be added to GitHub Secrets.

**Security Note**: Your upload key is stored in GitHub Secrets and used only for CI/CD. Even if compromised, you can reset it in Play Console without affecting your app's signing key or requiring users to reinstall.

---

## iOS Setup

### 1. Apple Developer Account

Ensure you have an active Apple Developer Program membership ($99/year).

### 2. Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** button
4. Select **App IDs** → **Continue**
5. Configure your App ID:
   - **Description**: Maypole (or similar)
   - **Bundle ID**: Explicit, e.g., `app.maypole.maypole`
   - Enable required capabilities (Push Notifications, etc.)
6. Click **Continue** → **Register**

### 3. Create Certificates

#### Distribution Certificate
1. On your Mac, open **Keychain Access**
2. **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter your email, select **Saved to disk**
4. Save the `.certSigningRequest` file
5. In Apple Developer Portal, go to **Certificates** → **+**
6. Select **Apple Distribution** → **Continue**
7. Upload your `.certSigningRequest` file
8. Download the certificate (`.cer` file)
9. Double-click to install it in Keychain Access
10. In Keychain Access, find your certificate
11. Right-click → **Export "Apple Distribution: [Your Name]"**
12. Save as `.p12` file with a password
13. **Save the password** - you'll need it for GitHub Secrets

### 4. Create Provisioning Profiles

#### App Store Provisioning Profile
1. In Apple Developer Portal, go to **Profiles** → **+**
2. Select **App Store** → **Continue**
3. Select your App ID → **Continue**
4. Select the distribution certificate you created → **Continue**
5. Name it (e.g., "Maypole App Store") → **Generate**
6. Download the `.mobileprovision` file

### 5. App Store Connect Setup

#### Create App
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** → **+** → **New App**
3. Fill in app information:
   - **Platforms**: iOS
   - **Name**: Maypole
   - **Primary Language**: English
   - **Bundle ID**: Select the one you created
   - **SKU**: Unique identifier (e.g., maypole-001)
   - **User Access**: Full Access
4. Click **Create**

#### Create API Key
1. In App Store Connect, go to **Users and Access**
2. Click **Keys** tab (under Integrations)
3. Click **+** to generate a new key
4. Name it "GitHub Actions Deploy"
5. Select **Access**: **App Manager** or **Developer**
6. Click **Generate**
7. Download the API key (`.p8` file) - **This is only available once!**
8. Note the **Key ID** and **Issuer ID** shown on the page
9. **Save all three**: the .p8 file, Key ID, and Issuer ID

#### Set Up TestFlight
1. In your app, go to **TestFlight** tab
2. Create Internal Testing group and add testers
3. Create External Testing group for beta testers

### 6. Create ExportOptions.plist

Create a file at `ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>app.maypole.maypole</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

Replace:
- `YOUR_TEAM_ID`: Find this in Apple Developer Portal → Membership
- `YOUR_PROVISIONING_PROFILE_NAME`: Name of your provisioning profile
- `app.maypole.maypole`: Your bundle ID

### 7. Prepare iOS Files for GitHub

Convert certificate to base64:
```bash
base64 -i certificate.p12 | tr -d '\n' > certificate_base64.txt
```

Convert provisioning profile to base64:
```bash
base64 -i YourProfile.mobileprovision | tr -d '\n' > provisioning_base64.txt
```

Convert App Store Connect API key to base64:
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n' > api_key_base64.txt
```

---

## GitHub Secrets Configuration

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

### Android Secrets

| Secret Name | Description | Where to Find |
|------------|-------------|---------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file | Content of `keystore_base64.txt` |
| `ANDROID_KEY_ALIAS` | Keystore key alias | The alias you used when creating keystore |
| `ANDROID_KEY_PASSWORD` | Key password | Password you set for the key |
| `ANDROID_STORE_PASSWORD` | Keystore password | Password you set for the keystore |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Service account JSON | Content of JSON file from Google Cloud |
| `GOOGLE_SERVICES_JSON_DEV` | Dev google-services.json | Content of dev flavor google-services.json |
| `GOOGLE_SERVICES_JSON_PROD` | Prod google-services.json | Content of prod flavor google-services.json |

### iOS Secrets

| Secret Name | Description | Where to Find |
|------------|-------------|---------------|
| `IOS_CERTIFICATE_BASE64` | Base64-encoded P12 certificate | Content of `certificate_base64.txt` |
| `IOS_CERTIFICATE_PASSWORD` | Certificate password | Password used when exporting P12 |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded provisioning profile | Content of `provisioning_base64.txt` |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | Create a secure random password |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | From App Store Connect → Keys |
| `APP_STORE_CONNECT_API_ISSUER_ID` | API Issuer ID | From App Store Connect → Keys |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded .p8 file | Content of `api_key_base64.txt` |
| `GOOGLE_SERVICE_INFO_PLIST_DEV` | Dev GoogleService-Info.plist | Content of iOS dev GoogleService-Info.plist |
| `GOOGLE_SERVICE_INFO_PLIST_PROD` | Prod GoogleService-Info.plist | Content of iOS prod GoogleService-Info.plist |

### Firebase Secrets (if not already added)

These should already exist, but verify:

| Secret Name | Description |
|------------|-------------|
| `FIREBASE_DEV_*` | All Firebase dev configuration values |
| `FIREBASE_PROD_*` | All Firebase prod configuration values |
| `MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV` | Dev Firebase service account JSON |
| `MAYPOLE_FIREBASE_SERVICE_ACCOUNT` | Prod Firebase service account JSON |

---

## Beta Branch Creation

Create and push the beta branch:

```bash
# Create beta branch from develop
git checkout develop
git pull origin develop
git checkout -b beta
git push -u origin beta

# Protect the beta branch (do this in GitHub UI)
# Go to Settings → Branches → Add rule
# Branch name pattern: beta
# Enable: Require pull request reviews before merging
```

### Beta Branch Workflow

The intended workflow is:
1. Development happens on feature branches
2. Feature branches merge into `develop`
3. When ready for beta testing, merge `develop` into `beta`
4. When beta is stable, merge `beta` into `master`/`main`

---

## Firebase Configuration

### Ensure Firebase Projects Exist

1. **Development**: `maypole-flutter-dev`
2. **Production**: `maypole-flutter` (or `maypole-flutter-ce6c3`)

### Firebase Rules Files

Ensure you have these files in your project root:
- `firestore.rules` - Firestore security rules
- `firestore.indexes.json` - Firestore indexes
- `storage.rules` - Storage security rules

### Firebase CLI Setup

If you haven't already, initialize Firebase in your project:

```bash
npm install -g firebase-tools
firebase login
firebase init
```

Select:
- Firestore (rules and indexes)
- Storage (rules)
- Hosting

---

## Testing the Workflows

### Test Development Workflow

```bash
# Make a small change
git checkout develop
echo "# Test" >> README.md
git add README.md
git commit -m "test: trigger dev workflow"
git push origin develop
```

Watch the workflow in GitHub Actions. It should:
- ✅ Run unit tests
- ✅ Build web and deploy to Firebase Hosting dev
- ✅ Build Android APK and upload to Play Store internal testing
- ✅ Build iOS IPA and upload to TestFlight internal

### Test Beta Workflow

```bash
# Merge develop into beta
git checkout beta
git merge develop
git push origin beta
```

This should:
- ✅ Build Android APK and upload to Play Store beta track
- ✅ Build iOS IPA and upload to TestFlight beta group

### Test Production Workflow

```bash
# Merge beta into master
git checkout master
git merge beta
git push origin master
```

This should:
- ✅ Build and deploy web to Firebase Hosting production
- ✅ Deploy Firebase services (Firestore rules, indexes, storage rules)
- ✅ Build Android APK and upload to Play Store production track
- ✅ Build iOS IPA and upload to App Store

---

## Troubleshooting

### Common Issues

#### Android: "Failed to find Build Tools"
- Ensure Java 17 is being used (specified in workflow)
- Check that `build.gradle.kts` is properly configured

#### iOS: "No signing identity found"
- Verify certificate is valid and not expired
- Check that provisioning profile matches the bundle ID
- Ensure certificate password is correct

#### Play Store: "Permission denied"
- Check service account has correct permissions in Play Console
- Verify service account JSON is complete and valid

#### TestFlight: "Invalid API Key"
- Verify Key ID and Issuer ID are correct
- Check that .p8 file is properly base64 encoded
- Ensure API key has correct permissions in App Store Connect

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Review the workflow YAML files for configuration issues
- Ensure all secrets are properly set in GitHub

---

## Beta Web App Strategy

As you mentioned wanting thoughts on a beta web version for enrolled users:

### Recommended Approach: Firebase Hosting Channels

1. **Use Preview Channels**: Create a dedicated preview channel for beta
   ```bash
   firebase hosting:channel:create beta --project maypole-flutter
   ```

2. **Update Beta Workflow**: Modify `beta.yml` to also deploy web to beta channel:
   ```yaml
   - name: Deploy to Firebase Hosting (Beta Channel)
     run: |
       firebase hosting:channel:deploy beta --project maypole-flutter --non-interactive
   ```

3. **Access Control**: 
   - Beta URL will be: `https://maypole-flutter--beta-XXXXXXXX.web.app`
   - Share this URL only with beta testers
   - Optionally add authentication check in your Flutter app to restrict beta features

### Alternative: Separate Firebase Project

Create a `maypole-flutter-beta` Firebase project and deploy there instead. This gives complete isolation but requires additional Firebase configuration.

---

## Maintenance

### Certificate Renewal

- **Apple Distribution Certificate**: Valid for 1 year, renew annually
- **Provisioning Profiles**: Valid for 1 year, renew annually
- **Android Upload Keystore**: Valid for 10000 days (27+ years)
  - Note: Even if compromised, you can reset your upload key in Play Console without affecting your app signing key or requiring users to reinstall

### Regular Updates

- Update Flutter version in workflows as needed
- Keep dependencies up to date
- Review and update security rules regularly

---

## Summary Checklist

### Android
- [ ] Upload keystore created and base64 encoded
- [ ] Android build.gradle.kts updated with signing config (✅ Already done)
- [ ] First AAB manually uploaded to enable Google Play App Signing
- [ ] App signing certificate downloaded from Play Console (for reference)
- [ ] Google Cloud service account created and configured
- [ ] Service account linked to Play Console with correct permissions
- [ ] Play Console testing tracks set up (internal and beta)

### iOS
- [ ] iOS certificates created and exported
- [ ] iOS provisioning profiles created
- [ ] App Store Connect API key created
- [ ] ExportOptions.plist created with correct values
- [ ] All GitHub secrets added
- [ ] Beta branch created and pushed
- [ ] Firebase projects configured
- [ ] Test workflow executions completed successfully

Once all items are checked, your automated deployment pipeline will be fully operational! 🚀
