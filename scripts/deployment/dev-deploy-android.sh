#!/bin/bash

# Deploy Android Dev Build to Play Store Internal Testing Track
# This script builds the dev release AAB and uploads it to Play Store internal testing

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "🔨 Building Android Dev Release AAB..."

# Bump build number
echo "📱 Bumping build number..."
chmod +x scripts/auto-bump-build.sh scripts/get-version.sh
./scripts/auto-bump-build.sh
echo "✅ Version bumped to: $(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
echo ""

# Check Android toolchain
echo "🔍 Checking Android toolchain..."
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
if [ ! -d "$ANDROID_SDK_ROOT/cmdline-tools/latest" ]; then
    echo "⚠️  Warning: Android cmdline-tools not found"
    echo "   This may cause issues with native library symbol stripping"
    echo "   Run './scripts/fix-android-toolchain.sh' to fix this"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Load environment variables
set -a
source "$(dirname "$0")/../../.env"
set +a

# Set environment
export ENVIRONMENT=dev

# Build the Android App Bundle
echo "📦 Building Android App Bundle (dev release)..."
flutter build appbundle \
    --release \
    --flavor dev \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo "📍 AAB location: build/app/outputs/bundle/devRelease/app-dev-release.aab"
echo ""

# Check if Gemfile exists
if [ ! -f "android/Gemfile" ]; then
    echo "⚠️  Warning: android/Gemfile not found"
    echo "   Fastlane may not be properly configured"
    echo "   Run: cd android && bundle install"
    exit 1
fi

# Check if Google Play service account JSON is configured
if [ -z "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" ]; then
    echo "❌ Error: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON environment variable not set"
    echo "   Please add it to your .env file:"
    echo "   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=\"/path/to/service-account.json\""
    exit 1
fi

# Verify the service account file exists
if [ ! -f "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" ]; then
    echo "❌ Error: Service account JSON file not found at:"
    echo "   $GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
    exit 1
fi

# Upload to Play Store Internal Testing
echo "☁️  Uploading to Play Store Internal Testing track..."
cd android

# Install/update bundle dependencies if needed (same as GitHub Actions does)
if [ ! -f "Gemfile.lock" ] || [ "Gemfile" -nt "Gemfile.lock" ]; then
    echo "📦 Installing/updating Fastlane dependencies..."
    bundle install
    echo "✅ Dependencies installed"
fi

# Deploy using Fastlane (same as GitHub Actions: line 200)
# Export the environment variable so it's available to Fastlane
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
bundle exec fastlane deploy_dev_internal

echo ""
echo "🎉 Dev build uploaded to Play Store Internal Testing!"
echo "   View at: https://play.google.com/console"
echo ""
echo "📋 Next steps:"
echo "   1. Go to Play Console → Release → Testing → Internal testing"
echo "   2. Add internal testers (email addresses)"
echo "   3. Share the testing link with your team"
