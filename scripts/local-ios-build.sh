#!/bin/bash
set -e  # Exit on error

echo "=========================================="
echo "Local iOS Build & Sign Test Script"
echo "=========================================="
echo ""

# Setup rbenv if available
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init - zsh)" 2>/dev/null || eval "$(rbenv init - bash)" 2>/dev/null || true
    export PATH="$HOME/.rbenv/shims:$PATH"
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if critical environment variables are set
echo "Checking environment variables..."
echo ""

MISSING_VARS=()

if [ -z "$APPLE_TEAM_ID" ]; then
    MISSING_VARS+=("APPLE_TEAM_ID")
fi

if [ -z "$APPLE_ID" ]; then
    MISSING_VARS+=("APPLE_ID")
fi

if [ -z "$MATCH_PASSWORD" ]; then
    MISSING_VARS+=("MATCH_PASSWORD")
fi

if [ -z "$MATCH_GCS_BUCKET" ]; then
    MISSING_VARS+=("MATCH_GCS_BUCKET")
fi

if [ -z "$MATCH_GCS_PROJECT_ID" ]; then
    MISSING_VARS+=("MATCH_GCS_PROJECT_ID")
fi

if [ -z "$GCP_SERVICE_ACCOUNT_KEY" ]; then
    MISSING_VARS+=("GCP_SERVICE_ACCOUNT_KEY")
fi

if [ -z "$APP_STORE_CONNECT_API_KEY_CONTENT" ]; then
    MISSING_VARS+=("APP_STORE_CONNECT_API_KEY_CONTENT")
fi

if [ -z "$APP_STORE_CONNECT_API_KEY_ID" ]; then
    MISSING_VARS+=("APP_STORE_CONNECT_API_KEY_ID")
fi

if [ -z "$APP_STORE_CONNECT_API_ISSUER_ID" ]; then
    MISSING_VARS+=("APP_STORE_CONNECT_API_ISSUER_ID")
fi

if [ -z "$IOS_BUNDLE_ID" ]; then
    MISSING_VARS+=("IOS_BUNDLE_ID")
fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "💡 Run this first to set up your environment:"
    echo "   source scripts/setup-local-env.sh"
    echo ""
    exit 1
fi

echo "✅ All required environment variables are set"
echo ""

# Navigate to iOS directory
cd "$PROJECT_ROOT/ios"

echo "=========================================="
echo "Step 1: Flutter Clean & Build"
echo "=========================================="
cd "$PROJECT_ROOT"
flutter clean
flutter pub get
flutter build ios --release --no-codesign \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=FIREBASE_DEV_IOS_API_KEY=$FIREBASE_DEV_IOS_API_KEY \
  --dart-define=FIREBASE_DEV_IOS_APP_ID=$FIREBASE_DEV_IOS_APP_ID \
  --dart-define=FIREBASE_DEV_MESSAGING_SENDER_ID=$FIREBASE_DEV_MESSAGING_SENDER_ID \
  --dart-define=FIREBASE_DEV_PROJECT_ID=$FIREBASE_DEV_PROJECT_ID \
  --dart-define=FIREBASE_DEV_AUTH_DOMAIN=$FIREBASE_DEV_AUTH_DOMAIN \
  --dart-define=FIREBASE_DEV_STORAGE_BUCKET=$FIREBASE_DEV_STORAGE_BUCKET

echo ""
echo "✅ Flutter build completed"
echo ""

# Navigate back to iOS directory
cd "$PROJECT_ROOT/ios"

echo "=========================================="
echo "Step 2: Setup GCP Credentials for Match"
echo "=========================================="

# Create GCP credentials file if GCP_SERVICE_ACCOUNT_KEY is set
if [ -n "$GCP_SERVICE_ACCOUNT_KEY" ]; then
    mkdir -p ~/.config/gcloud
    echo "$GCP_SERVICE_ACCOUNT_KEY" > ~/.config/gcloud/application_default_credentials.json
    export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
    echo "✅ GCP credentials configured"
else
    echo "⚠️  GCP_SERVICE_ACCOUNT_KEY not set - match may fail"
fi

echo ""

echo "=========================================="
echo "Step 3: Setup App Store Connect API Key"
echo "=========================================="

if [ -n "$APP_STORE_CONNECT_API_KEY_CONTENT" ] && [ -n "$APP_STORE_CONNECT_API_KEY_ID" ]; then
    mkdir -p ~/private_keys
    echo "$APP_STORE_CONNECT_API_KEY_CONTENT" > ~/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8
    export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
    export APP_STORE_CONNECT_API_KEY_KEY_ID="$APP_STORE_CONNECT_API_KEY_ID"
    export APP_STORE_CONNECT_API_KEY_ISSUER_ID="$APP_STORE_CONNECT_API_ISSUER_ID"
    echo "✅ App Store Connect API key configured"
else
    echo "⚠️  App Store Connect API key not configured - upload will fail"
fi

echo ""

echo "=========================================="
echo "Step 4: Install Fastlane Dependencies"
echo "=========================================="

if [ ! -d "vendor/bundle" ]; then
    bundle config set --local path 'vendor/bundle'
    bundle install
else
    echo "✅ Fastlane dependencies already installed"
fi

echo ""

echo "=========================================="
echo "Step 5: Run Fastlane Deploy (WITH VERBOSE OUTPUT)"
echo "=========================================="
echo "This will show you exactly what's happening..."
echo ""

# Set up match environment variables
export MATCH_GCS_BUCKET="${MATCH_GCS_BUCKET}"
export MATCH_GCS_PROJECT_ID="${MATCH_GCS_PROJECT_ID}"
export MATCH_PASSWORD="${MATCH_PASSWORD}"
export APPLE_ID="${APPLE_ID}"

# Run fastlane with verbose output
bundle exec fastlane ios deploy_dev --verbose

echo ""
echo "=========================================="
echo "✅ BUILD SUCCESSFUL!"
echo "=========================================="
echo ""
echo "IPA Location: ios/build/Runner.ipa"
echo ""
