# Environment Setup Guide

## Firebase Configuration

### Getting Firebase Credentials

1. **Development Environment (maypole-flutter-dev)**
    - Go to [Firebase Console](https://console.firebase.google.com/)
    - Select project: `maypole-flutter-dev`
    - Navigate to Project Settings → General
    - Download configuration files:
        - Android: `google-services.json`
        - iOS: `GoogleService-Info.plist`
    - Copy API keys and project details to `.env.local`

2. **Production Environment (maypole-flutter-ce6c3)**
    - Same process but for `maypole-flutter-ce6c3` project

### Setting up .env.local

1. Copy `.env.local.example` to `.env.local`
2. Fill in the values from Firebase Console
3. **Never commit `.env.local` to git**

### Required Files Checklist

- [ ] `.env.local` (from Firebase Console or secure storage)
- [ ] `android/app/google-services.json` (dev or prod version)
- [ ] `ios/Runner/GoogleService-Info.plist` (dev or prod version)

### Validation

Use the validation script to check your configuration:

```bash
# Validate development environment
./scripts/validate-env.sh dev

# Validate production environment  
./scripts/validate-env.sh prod
```

### Switching Between Environments

**For Development:**

```bash
# Use dev Firebase project
cp firebase-configs/dev/google-services.json android/app/
cp firebase-configs/dev/GoogleService-Info.plist ios/Runner/
cp firebase-configs/dev/.env.local .
```

**For Production:**

```bash
# Use prod Firebase project
cp firebase-configs/prod/google-services.json android/app/
cp firebase-configs/prod/.env.local .
```

## GitHub Actions Integration

### How It Works

The GitHub Actions workflows now automatically create `.env.local` from GitHub Secrets:

1. **Secrets Storage**: All Firebase credentials are stored as GitHub repository secrets
2. **Dynamic Creation**: Each workflow creates `.env.local` at build time
3. **Environment Switching**: Workflows automatically use the correct environment variables

### Required GitHub Secrets

#### Development Secrets (for `develop` branch)

```
FIREBASE_DEV_WEB_API_KEY
FIREBASE_DEV_WEB_APP_ID
FIREBASE_DEV_WEB_MEASUREMENT_ID
FIREBASE_DEV_ANDROID_API_KEY
FIREBASE_DEV_ANDROID_APP_ID
FIREBASE_DEV_IOS_API_KEY
FIREBASE_DEV_IOS_APP_ID
FIREBASE_DEV_MESSAGING_SENDER_ID
FIREBASE_DEV_PROJECT_ID
FIREBASE_DEV_AUTH_DOMAIN
FIREBASE_DEV_STORAGE_BUCKET
IOS_BUNDLE_ID
MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV
```

#### Production Secrets (for `master` branch)

```
FIREBASE_PROD_WEB_API_KEY
FIREBASE_PROD_WEB_APP_ID
FIREBASE_PROD_WEB_MEASUREMENT_ID
FIREBASE_PROD_ANDROID_API_KEY
FIREBASE_PROD_ANDROID_APP_ID
FIREBASE_PROD_IOS_API_KEY
FIREBASE_PROD_IOS_APP_ID
FIREBASE_PROD_WINDOWS_APP_ID
FIREBASE_PROD_WINDOWS_MEASUREMENT_ID
FIREBASE_PROD_MESSAGING_SENDER_ID
FIREBASE_PROD_PROJECT_ID
FIREBASE_PROD_AUTH_DOMAIN
FIREBASE_PROD_STORAGE_BUCKET
IOS_BUNDLE_ID
MAYPOLE_FIREBASE_SERVICE_ACCOUNT
```

### Setting Up GitHub Secrets

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add each secret with the exact name shown above
3. Use the values from your `.env.local` file or Firebase Console

### Workflow Benefits

- **Secure**: Secrets never appear in logs or code
- **Automatic**: No manual configuration needed in CI/CD
- **Environment-aware**: Automatically uses correct Firebase project
- **Consistent**: Same credential format for local and CI/CD

## Security Notes

- **Never commit sensitive files to git**
- Use `.gitignore` to exclude:
    - `.env.local`
    - `google-services.json` (if contains sensitive data)
    - `GoogleService-Info.plist`
- Store backup copies in secure, private locations
- Rotate keys periodically for production

## Emergency Recovery

If you lose access to credentials:

1. Firebase Console → Project Settings → Service Accounts
2. Generate new credentials
3. Update all environments
4. Revoke old credentials

## Contact

For access to secure credential storage, contact: [team-admin-email]