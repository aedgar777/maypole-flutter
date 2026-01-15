# Android Deployment Setup Guide

## Prerequisites

Before you can deploy Android builds to the Play Store, you need to complete these setup steps.

## 1. Android Toolchain

Ensure the Android toolchain is properly configured:

```bash
./scripts/fix-android-toolchain.sh
```

This installs:
- Android cmdline-tools
- Accepts SDK licenses
- Configures Java environment

Verify with:
```bash
flutter doctor
```

Should show: `[✓] Android toolchain - develop for Android devices`

## 2. Fastlane Setup

### Install Fastlane Dependencies

The project uses **Fastlane 2.230.0** (latest stable version) for Android deployment automation.

```bash
cd android
bundle install
```

This installs Fastlane and all required gems based on the `Gemfile`.

**Note**: Fastlane 2.x requires Bundler < 3.0. If you have Bundler 4.x installed:
```bash
gem install bundler:2.7.2
bundle _2.7.2_ install
```

### Files in the Repository

- `android/Gemfile` - Ruby gem dependencies (Fastlane ~> 2.230)
- `android/Gemfile.lock` - Locked gem versions for reproducibility
- `android/.ruby-version` - Specifies Ruby 3.2.0 for consistency
- `android/fastlane/Fastfile` - Fastlane lanes configuration
- `android/fastlane/Appfile` - App package configuration

### How GitHub Actions Handles This

The GitHub workflows (`.github/workflows/develop.yml` and `beta.yml`) use the `ruby/setup-ruby@v1` action:

```yaml
- name: Setup Ruby for Fastlane
  uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.2.0'
    bundler-cache: true  # Automatically runs bundle install and caches gems
    working-directory: android
```

This action:
1. Installs Ruby 3.2.0
2. Detects the `Gemfile` in the android directory
3. Automatically runs `bundle install`
4. Caches the installed gems for faster subsequent runs
5. Uses the appropriate Bundler version (2.x) automatically

## 3. Google Play Service Account

To upload builds to the Play Store, you need a Google Play Service Account with API access.

### Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Go to **IAM & Admin → Service Accounts**
4. Click **Create Service Account**
5. Name it (e.g., "Maypole Fastlane Deployer")
6. Click **Create and Continue**
7. Skip roles for now, click **Done**

### Enable Google Play Android Developer API

1. Go to [Google Cloud Console APIs](https://console.cloud.google.com/apis/library)
2. Search for "Google Play Android Developer API"
3. Click **Enable**

### Grant Service Account Access in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Setup → API access**
4. Link your Google Cloud project if not already linked
5. Under **Service accounts**, find your service account
6. Click **Grant access**
7. Under **App permissions**, add your app
8. Under **Account permissions**, grant:
   - **Releases**: View, Create and edit releases, etc.
   - **Release to production, exclude devices, and use Play App Signing**
9. Click **Invite user**
10. Click **Send invite**

### Generate Service Account Key

1. Go back to [Google Cloud Console → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. Click on your service account
3. Go to **Keys** tab
4. Click **Add Key → Create new key**
5. Select **JSON**
6. Click **Create** (downloads JSON file)

### Configure Environment Variable

Add to your `.env` file (in project root):

```bash
# Google Play Store Service Account JSON path (absolute path)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="/path/to/your/service-account-key.json"
```

**Security Note**: 
- Never commit this JSON file to Git
- Keep it in a secure location outside your project
- Add `*.json` to `.gitignore` if storing in project directory

## 4. Android Signing Configuration

For release builds, you need a signing key.

### Create Upload Key (if you don't have one)

```bash
keytool -genkey -v -keystore ~/maypole-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Answer the prompts and remember:
- Keystore password
- Key password
- Alias name

### Configure Key Properties

Create `android/key.properties` (ignored by Git):

```properties
storeFile=/Users/yourname/maypole-upload-key.jks
storePassword=your_keystore_password
keyAlias=upload
keyPassword=your_key_password
```

**Important**: This file is in `.gitignore` - never commit it!

## 5. Test the Setup

### Test Build Only (No Upload)

```bash
flutter build appbundle --release --flavor dev --dart-define=ENVIRONMENT=dev
```

Should create: `build/app/outputs/bundle/devRelease/app-dev-release.aab`

### Test Full Deployment

```bash
./scripts/deployment/dev-deploy-android.sh
```

This will:
1. Check Android toolchain
2. Build the AAB
3. Upload to Play Store Internal Testing track

## Troubleshooting

### "Could not locate Gemfile"

**Solution**: Create the Gemfile:
```bash
cd android
cat > Gemfile << 'EOF'
source "https://rubygems.org"

gem "fastlane", "~> 2.220"
EOF
bundle install
```

### "cmdline-tools component is missing"

**Solution**: Run the fix script:
```bash
./scripts/fix-android-toolchain.sh
```

### "Google Play API error: Unauthorized"

**Possible causes**:
1. Service account JSON path is wrong
2. Service account doesn't have proper permissions
3. Google Play Android Developer API is not enabled
4. Service account is not linked in Play Console

**Solution**:
1. Check `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` path in `.env`
2. Verify file exists and is readable
3. Re-check Play Console permissions (step 3 above)

### "No application was found for the given package name"

**Solution**: You need to manually upload your first APK/AAB through the Play Console web interface. After the first upload, Fastlane can handle subsequent uploads.

### Build succeeds but upload fails

Check the Fastlane output for specific errors. Common issues:
- Version code must be higher than existing releases
- Package name mismatch
- Signing key mismatch (if already using Play App Signing)

## Deployment Tracks

### Internal Testing (dev builds)
- Lane: `deploy_dev_internal`
- Track: `internal`
- Used for: Development testing, QA
- Deployed via: `./scripts/deployment/dev-deploy-android.sh`

### Open Testing (beta builds)
- Lane: `deploy_beta_open`
- Track: `beta`
- Used for: Public beta testing
- Deployed via: `./scripts/deployment/beta-deploy-android.sh`

### Production
- Lane: `promote_to_production`
- Track: `production`
- Used for: Public release
- Deployed via: Play Console or `./scripts/deployment/prod-deploy-android.sh`

## Next Steps

1. ✅ Complete all setup steps above
2. ✅ Test with internal track deployment
3. Configure beta track deployment
4. Set up production release workflow

## See Also

- [Main Scripts README](../README.md)
- [Deployment README](README.md)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Play Console Help](https://support.google.com/googleplay/android-developer/)
