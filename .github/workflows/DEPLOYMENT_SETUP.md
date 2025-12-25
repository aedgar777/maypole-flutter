# Deployment Setup Guide

This guide will walk you through setting up automated deployments for the Maypole Flutter app across three environments: Development, Beta, and Production.

## Table of Contents

1. [iOS Setup](#ios-setup)
2. [GitHub Secrets Configuration](#github-secrets-configuration)
3. [Beta Branch Creation](#beta-branch-creation)
4. [Firebase Configuration](#firebase-configuration)
5. [Testing the Workflows](#testing-the-workflows)

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

### Step 1: Configure GitHub Actions Permissions

**IMPORTANT**: Enable GitHub Actions to push version bumps back to your repository:

1. Go to your GitHub repository → **Settings** → **Actions** → **General**
2. Scroll down to **Workflow permissions**
3. Select **Read and write permissions** (this allows workflows to push version bumps)
4. Check ✅ **Allow GitHub Actions to create and approve pull requests** (optional)
5. Click **Save**

> **Why is this needed?** The workflows automatically increment the build number and commit it back to the repository to ensure each deployment has a unique version code. Without write permissions, you'll get a 403 error when the workflow tries to push.

### Step 2: Add Repository Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

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
- ✅ Build iOS IPA and upload to App Store

---

## Troubleshooting

### Common Issues

#### iOS: "No signing identity found"
- Verify certificate is valid and not expired
- Check that provisioning profile matches the bundle ID
- Ensure certificate password is correct

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

### Regular Updates

- Update Flutter version in workflows as needed
- Keep dependencies up to date
- Review and update security rules regularly

---

## Summary Checklist

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
