# Deployment Setup Guide

This guide will walk you through setting up automated deployments for the Maypole Flutter app across three environments: Development, Beta, and Production.

**Key Feature**: This setup uses **Fastlane Match** to automate iOS code signing, eliminating the need for manual certificate management.

## Table of Contents

1. [iOS Setup with Fastlane Match](#ios-setup-with-fastlane-match)
2. [GitHub Secrets Configuration](#github-secrets-configuration)
3. [Beta Branch Creation](#beta-branch-creation)
4. [Firebase Configuration](#firebase-configuration)
5. [Testing the Workflows](#testing-the-workflows)

---

## iOS Setup with Fastlane Match

### Why Fastlane Match?

**Fastlane Match** is the modern, automated approach to iOS code signing that:
- ✅ Automatically creates and manages certificates and provisioning profiles
- ✅ Stores them securely in a private Git repository
- ✅ Makes them accessible to all team members and CI/CD systems
- ✅ Eliminates manual certificate creation and Keychain Access steps
- ✅ Prevents "works on my machine" signing issues

### Prerequisites

1. **Apple Developer Account**: Active membership ($99/year)
2. **GitHub Account**: For storing certificates repository (private)
3. **App Store Connect API Key**: For automated uploads

---

### Step 1: Create App ID in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** button
4. Select **App IDs** → **Continue**
5. Configure your App ID:
   - **Description**: Maypole
   - **Bundle ID**: Explicit, e.g., `app.maypole.maypole`
   - Enable required capabilities (Push Notifications, Sign in with Apple, etc.)
6. Click **Continue** → **Register**

**Save your Bundle ID** - you'll need it for GitHub Secrets.

---

### Step 2: Create App Store Connect API Key

This key allows Fastlane to upload builds and manage your app automatically.

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **Users and Access** (in the top menu)
3. Click the **Keys** tab (under Integrations section)
4. Click **+** to generate a new key
5. Configure the key:
   - **Name**: "GitHub Actions Deploy" (or similar)
   - **Access**: Select **App Manager** (recommended) or **Developer**
6. Click **Generate**
7. **Download the `.p8` file** - This is only available ONCE!
8. **Note the Key ID** (e.g., `ABC123DEF4`)
9. **Note the Issuer ID** (e.g., `12345678-1234-1234-1234-123456789012`)

**Keep all three safe:**
- ✅ `.p8` file content
- ✅ Key ID
- ✅ Issuer ID

---

### Step 3: Create App in App Store Connect

1. In [App Store Connect](https://appstoreconnect.apple.com/), click **My Apps** → **+** → **New App**
2. Fill in app information:
   - **Platforms**: iOS
   - **Name**: Maypole
   - **Primary Language**: English
   - **Bundle ID**: Select the one you created in Step 1
   - **SKU**: Unique identifier (e.g., `maypole-001`)
   - **User Access**: Full Access
3. Click **Create**

#### Set Up TestFlight Groups

1. In your app, go to **TestFlight** tab
2. Create Internal Testing group (for development builds)
3. Create External Testing group named **"Beta Testers"** (for beta builds)
4. Add testers to each group as needed

---

### Step 4: Generate App-Specific Password

Fastlane needs this to authenticate with your Apple ID.

1. Go to [appleid.apple.com](https://appleid.apple.com/)
2. Sign in with your Apple ID (the one used for your Developer account)
3. In the **Security** section, find **App-Specific Passwords**
4. Click **Generate Password**
5. Name it "Fastlane GitHub Actions" (or similar)
6. **Save the generated password** - you'll need it for GitHub Secrets

---

### Step 5: Create Private Repository for Certificates

Fastlane Match stores certificates in a private Git repository.

1. Go to GitHub and create a **new private repository**
   - Name: `maypole-ios-certificates` (or similar)
   - **IMPORTANT**: Make it **Private**
   - Don't add README or any files
2. Copy the repository URL (e.g., `https://github.com/yourusername/maypole-ios-certificates.git`)
3. **Save this URL** - you'll need it for GitHub Secrets

---

### Step 6: Create GitHub Personal Access Token

This allows Fastlane Match to access your certificates repository from GitHub Actions.

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token** → **Generate new token (classic)**
3. Configure the token:
   - **Note**: "Fastlane Match Certificates"
   - **Expiration**: 1 year (or No expiration for simplicity)
   - **Scopes**: Select **repo** (full control of private repositories)
4. Click **Generate token**
5. **Copy the token immediately** - you won't be able to see it again!

Convert it to Base64 authorization string:

```bash
echo -n "your_github_username:your_personal_access_token" | base64
```

**Save this Base64 string** - you'll need it as `MATCH_GIT_BASIC_AUTHORIZATION`.

---

### Step 7: Initialize Fastlane Match Locally (One-Time Setup)

This step creates your certificates and provisioning profiles and stores them in your private repository.

#### 7.1 Install Fastlane

```bash
# Navigate to your project
cd /path/to/maypole-flutter

# Install Ruby dependencies
cd ios
bundle install
```

#### 7.2 Set Environment Variables

Create a temporary file with your credentials (don't commit this!):

```bash
# Create a temporary .env file in the ios directory
cat > ios/.env.local << EOF
MATCH_GIT_URL=https://github.com/yourusername/maypole-ios-certificates.git
APPLE_ID=your.apple.id@email.com
APPLE_TEAM_ID=YOUR_TEAM_ID
IOS_BUNDLE_ID=app.maypole.maypole
EOF
```

**To find your Team ID:**
- Go to [Apple Developer Portal](https://developer.apple.com/account/)
- Click **Membership** in the sidebar
- Your Team ID is shown (e.g., `ABC123DEF4`)

#### 7.3 Run Fastlane Match

```bash
cd ios

# Source your environment variables
export $(cat .env.local | xargs)

# Initialize Match and create certificates
bundle exec fastlane match appstore

# When prompted:
# 1. Create a strong passphrase for encrypting certificates
# 2. Enter your Apple ID password
# 3. May require 2FA code - enter it when prompted
```

**IMPORTANT**: Save the passphrase you create - this is your `MATCH_PASSWORD` for GitHub Secrets!

#### 7.4 Verify Success

After Match completes successfully, your certificates repository should contain:
- Certificates encrypted in the repo
- Provisioning profiles
- A `README.md` explaining the setup

**Clean up:**

```bash
# Remove the temporary environment file
rm ios/.env.local
```

---

### Step 8: Prepare Secrets for GitHub

You should now have collected:

| Secret Name | Value | Source |
|------------|-------|--------|
| `MATCH_GIT_URL` | `https://github.com/user/maypole-ios-certificates.git` | Step 5 |
| `MATCH_PASSWORD` | Passphrase you created | Step 7.3 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 string | Step 6 |
| `APPLE_ID` | Your Apple ID email | Your Apple account |
| `APPLE_TEAM_ID` | Team ID (e.g., `ABC123DEF4`) | Step 7.2 |
| `IOS_BUNDLE_ID` | Bundle identifier (e.g., `app.maypole.maypole`) | Step 1 |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID | Step 2 |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID | Step 2 |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Contents of `.p8` file | Step 2 |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App-specific password | Step 4 |

For the `.p8` file:

```bash
# Read the contents of your .p8 file (don't base64 encode it)
cat /path/to/AuthKey_XXXXXXXXXX.p8
```

Copy the entire contents including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines.

---

## GitHub Secrets Configuration

### Step 1: Configure GitHub Actions Permissions

**IMPORTANT**: Enable GitHub Actions to push version bumps back to your repository:

1. Go to your GitHub repository → **Settings** → **Actions** → **General**
2. Scroll down to **Workflow permissions**
3. Select **Read and write permissions**
4. Check ✅ **Allow GitHub Actions to create and approve pull requests** (optional)
5. Click **Save**

---

### Step 2: Add Repository Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

#### iOS Secrets (Fastlane Match)

| Secret Name | Description | Value |
|------------|-------------|-------|
| `MATCH_GIT_URL` | Private repo for certificates | From Step 8 above |
| `MATCH_PASSWORD` | Encryption passphrase | From Step 8 above |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 GitHub token | From Step 8 above |
| `APPLE_ID` | Your Apple ID email | From Step 8 above |
| `APPLE_TEAM_ID` | Apple Developer Team ID | From Step 8 above |
| `IOS_BUNDLE_ID` | App bundle identifier | From Step 8 above |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | From Step 8 above |
| `APP_STORE_CONNECT_API_ISSUER_ID` | API Issuer ID | From Step 8 above |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Full `.p8` file content | From Step 8 above |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App-specific password | From Step 8 above |
| `GOOGLE_SERVICE_INFO_PLIST_DEV` | Dev GoogleService-Info.plist | Full XML content of iOS dev file |
| `GOOGLE_SERVICE_INFO_PLIST_PROD` | Prod GoogleService-Info.plist | Full XML content of iOS prod file |

#### Firebase Secrets

These should already exist from your Firebase setup:

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
```

### Protect the Beta Branch (Optional)

1. Go to GitHub → **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `beta`
3. Enable: **Require pull request reviews before merging**
4. Click **Create**

### Beta Branch Workflow

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

If you haven't already:

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
- ✅ Build iOS and upload to TestFlight internal

### Test Beta Workflow

```bash
# Merge develop into beta
git checkout beta
git merge develop
git push origin beta
```

This should:
- ✅ Build iOS and upload to TestFlight beta group (external testers)

### Test Production Workflow

```bash
# Merge beta into master
git checkout master
git merge beta
git push origin master
```

This should:
- ✅ Build and deploy web to Firebase Hosting production
- ✅ Deploy Firebase services (rules, indexes)
- ✅ Build iOS and upload to TestFlight/App Store

---

## Troubleshooting

### Common Issues with Fastlane Match

#### "Couldn't find the private key"
- **Solution**: Verify `MATCH_GIT_BASIC_AUTHORIZATION` is correctly set
- Check that your GitHub PAT has `repo` scope
- Ensure the certificates repository URL is correct

#### "Wrong password"
- **Solution**: Verify `MATCH_PASSWORD` matches the passphrase you set during initialization

#### "Couldn't find provisioning profile"
- **Solution**: Run `bundle exec fastlane match appstore` locally again to regenerate profiles
- Check that `IOS_BUNDLE_ID` matches exactly

#### "Certificate has expired"
- **Solution**: Run `bundle exec fastlane match nuke distribution` (careful!)
- Then run `bundle exec fastlane match appstore` to create new ones

### Re-running Match Setup

If you need to start over:

```bash
cd ios

# Set environment variables again
export MATCH_GIT_URL="your_url"
export APPLE_ID="your_email"
export APPLE_TEAM_ID="your_team_id"
export IOS_BUNDLE_ID="your_bundle_id"

# Nuke existing certificates (CAREFUL - this affects all team members!)
bundle exec fastlane match nuke distribution

# Create new certificates
bundle exec fastlane match appstore
```

### TestFlight Upload Issues

#### "Invalid API Key"
- Verify all three values: Key ID, Issuer ID, and .p8 content
- Ensure the `.p8` content includes the BEGIN/END lines
- Check that API key has correct permissions in App Store Connect

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Review the Fastlane documentation: [https://docs.fastlane.tools/actions/match/](https://docs.fastlane.tools/actions/match/)
- Ensure all secrets are properly set in GitHub

---

## Maintenance

### Certificate Renewal

- **Apple Distribution Certificate**: Valid for 1 year, auto-renewed by Match
- **Provisioning Profiles**: Valid for 1 year, auto-renewed by Match
- **App Store Connect API Key**: No expiration
- **GitHub PAT**: Expires based on your setting (renew when needed)

### When Certificates Expire

Fastlane Match handles renewal automatically. If needed manually:

```bash
cd ios
bundle exec fastlane match appstore --force
```

This will create new certificates and update your certificates repository.

### Regular Updates

- Update Flutter version in workflows as needed
- Keep Fastlane and dependencies up to date: `bundle update`
- Review and update security rules regularly

---

## Summary Checklist

### iOS Setup
- [ ] App ID created in Apple Developer Portal
- [ ] App Store Connect API key created (Key ID, Issuer ID, .p8 file)
- [ ] App created in App Store Connect
- [ ] TestFlight groups created (Internal, Beta Testers)
- [ ] App-specific password generated
- [ ] Private certificates repository created
- [ ] GitHub Personal Access Token created
- [ ] Fastlane Match initialized locally
- [ ] All iOS GitHub secrets added

### General Setup
- [ ] Beta branch created and pushed
- [ ] Firebase projects configured
- [ ] GitHub Actions permissions set (read/write)
- [ ] Test workflow executions completed successfully

Once all items are checked, your automated deployment pipeline is fully operational! 🚀

---

## Advantages of Fastlane Match

Compared to manual certificate management, Fastlane Match provides:

1. **Zero Manual Work**: No Keychain Access, no certificate exports, no .p12 files
2. **Team Friendly**: New team members get certificates automatically
3. **CI/CD Ready**: Works seamlessly in GitHub Actions, GitLab CI, etc.
4. **Automatic Renewal**: Handles certificate expiration automatically
5. **Single Source of Truth**: All certificates in one encrypted repository
6. **Rollback Capability**: Git history of all certificate changes

This is the modern, industry-standard approach to iOS code signing! 🎉
