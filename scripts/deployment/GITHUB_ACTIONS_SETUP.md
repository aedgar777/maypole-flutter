# GitHub Actions CI/CD Setup

This document explains how the GitHub Actions workflows handle Android deployments and how to replicate the setup locally.

## Overview

The project has three main GitHub Actions workflows:

1. **Development Deployment** (`.github/workflows/develop.yml`) - Deploys to dev/internal testing
2. **Beta Deployment** (`.github/workflows/beta.yml`) - Deploys to beta/open testing
3. **Production Deployment** (`.github/workflows/production.yml`) - Deploys to production

## How Android Deployment Works in GitHub Actions

### Key Setup (develop.yml lines 184-200)

```yaml
- name: Setup Ruby for Fastlane
  uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.2.0'
    bundler-cache: true        # ← This is the key!
    working-directory: android

- name: Deploy to Play Store Internal Testing with Fastlane
  working-directory: android
  env:
    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
  run: |
    # Create temp file for service account JSON
    echo "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" > ../play-store-service-account.json
    export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="../play-store-service-account.json"
    
    bundle exec fastlane deploy_dev_internal
```

### What `bundler-cache: true` Does

The `ruby/setup-ruby@v1` action with `bundler-cache: true`:

1. **Detects Gemfile**: Looks for `Gemfile` in the `working-directory`
2. **Reads .ruby-version**: Uses specified Ruby version (3.2.0)
3. **Installs Bundler**: Automatically selects Bundler 2.x (compatible with Fastlane 2.x)
4. **Runs bundle install**: Installs all gems from `Gemfile.lock`
5. **Caches gems**: Saves gems to GitHub Actions cache for faster subsequent runs
6. **Restores cache**: On next run, restores cached gems if `Gemfile.lock` unchanged

This is **equivalent to manually running**:
```bash
cd android
bundle install
```

But with automatic caching and version management!

## Replicating GitHub Actions Setup Locally

### 1. Ensure Correct Ruby Version

Use rbenv or rvm to install Ruby 3.2.0:

```bash
# Using rbenv (recommended)
rbenv install 3.2.0
rbenv local 3.2.0

# Or using rvm
rvm install 3.2.0
rvm use 3.2.0
```

The `.ruby-version` file in the android directory will make this automatic with rbenv.

### 2. Install Compatible Bundler

Fastlane 2.x requires Bundler < 3.0:

```bash
gem install bundler:2.7.2
```

### 3. Install Gems

```bash
cd android
bundle _2.7.2_ install
```

Or if Bundler 2.7.2 is your default:
```bash
cd android
bundle install
```

### 4. Set Environment Variables

GitHub Actions uses secrets. Locally, use `.env` file or export:

```bash
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="/path/to/service-account.json"
```

### 5. Run Deployment

```bash
cd android
bundle exec fastlane deploy_dev_internal
```

Or use the deployment script which handles all of this:
```bash
./scripts/deployment/dev-deploy-android.sh
```

## Secrets Configuration in GitHub

The workflows require these secrets to be set in GitHub repository settings:

### Android Secrets

- `PLAY_STORE_SERVICE_ACCOUNT_JSON` - Google Play service account JSON content
- `ANDROID_KEYSTORE_BASE64` - Base64-encoded keystore file
- `ANDROID_STORE_PASSWORD` - Keystore password
- `ANDROID_KEY_PASSWORD` - Key password
- `ANDROID_KEY_ALIAS` - Key alias
- `GOOGLE_SERVICES_JSON_DEV` - Firebase google-services.json for dev flavor
- `GOOGLE_SERVICES_JSON_PROD` - Firebase google-services.json for prod flavor

### iOS Secrets

- `APP_STORE_CONNECT_API_KEY_ID` - App Store Connect API key ID
- `APP_STORE_CONNECT_API_ISSUER_ID` - API issuer ID
- `APP_STORE_CONNECT_API_KEY_CONTENT` - API key file content (.p8)
- `MATCH_GCS_BUCKET` - Google Cloud Storage bucket for Match
- `MATCH_PASSWORD` - Match encryption password
- `GCP_SERVICE_ACCOUNT_KEY` - GCP service account for Match
- And more...

### Firebase Secrets

- `MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV` - Firebase service account for dev
- `MAYPOLE_FIREBASE_SERVICE_ACCOUNT` - Firebase service account for prod
- `FIREBASE_*` - Various Firebase configuration values

## Workflow Triggers

### Development (develop.yml)
- **Trigger**: Push to `develop` branch
- **Actions**:
  1. Run tests
  2. Bump build number
  3. Deploy Firebase (rules, indexes, functions)
  4. Build and deploy Android to Internal Testing
  5. Build and deploy iOS to TestFlight
  6. Build and deploy Web to Firebase Hosting

### Beta (beta.yml)
- **Trigger**: Push to `beta` branch
- **Actions**:
  1. Bump patch version
  2. Build and deploy Android to Open Testing (beta track)
  3. Build and deploy iOS to TestFlight Beta
  4. Build and deploy Web to beta channel

### Production (production.yml)
- **Trigger**: Manual workflow dispatch or push to `main`
- **Actions**: Similar to beta but for production tracks

## Differences Between GitHub Actions and Local

| Aspect | GitHub Actions | Local Development |
|--------|---------------|-------------------|
| Ruby/Bundler setup | Automatic via `ruby/setup-ruby` | Manual installation |
| Gem caching | Automatic | Manual (or none) |
| Secrets | GitHub Secrets | `.env` file or environment variables |
| Service account JSON | Stored in secrets, created as temp file | Permanent file on disk |
| Keystore | Base64 decoded from secret | Stored in `android/key.properties` |
| Parallel jobs | Runs Android, iOS, Web in parallel | Run sequentially |
| Build environment | Clean Ubuntu/macOS runners | Your machine state |

## Benefits of GitHub Actions Setup

1. **Automatic gem management** - No manual bundle install needed
2. **Fast gem installation** - Gems are cached between runs
3. **Clean environment** - Each run starts fresh
4. **Secrets management** - Credentials never stored in code
5. **Parallel builds** - Android, iOS, Web build simultaneously
6. **Version control** - Automatic version bumping with git commits

## Debugging GitHub Actions

### View Logs

1. Go to **Actions** tab in GitHub repository
2. Click on the workflow run
3. Click on the specific job (e.g., "Build and Deploy Android (Dev Internal)")
4. Expand the steps to see detailed logs

### Common Issues

**"Could not locate Gemfile"**
- Check `working-directory` is set to `android` in the workflow
- Verify `android/Gemfile` exists in the repository

**"Bundler version conflict"**
- The `ruby/setup-ruby` action handles this automatically
- Ensure you're using `bundler-cache: true`

**"Permission denied" uploading to Play Store**
- Check `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret is set
- Verify service account has proper permissions in Play Console
- Ensure service account is granted access in Play Console API settings

**Build succeeds but deployment fails**
- Check Fastlane logs in the workflow output
- Common: Version code must be higher than existing releases
- Common: First release must be uploaded manually through Play Console

## Local Development Best Practices

1. **Use the deployment scripts** - They replicate GitHub Actions logic
2. **Keep Gemfile.lock in git** - Ensures same versions locally and in CI
3. **Use .ruby-version** - Automatic Ruby version switching with rbenv
4. **Test locally first** - Catch issues before pushing to CI
5. **Match GitHub Actions setup** - Use same Ruby and Bundler versions

## Updating Gems

### Locally

```bash
cd android
bundle _2.7.2_ update fastlane
git add Gemfile.lock
git commit -m "chore: update fastlane"
```

### In GitHub Actions

No action needed! The workflow will automatically use the updated `Gemfile.lock`.

## See Also

- [ANDROID_SETUP.md](ANDROID_SETUP.md) - Complete Android deployment setup
- [SETUP.md](SETUP.md) - General deployment setup guide
- [ruby/setup-ruby action docs](https://github.com/ruby/setup-ruby)
- [Fastlane documentation](https://docs.fastlane.tools/)
