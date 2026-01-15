#!/bin/bash

# Deploy iOS Dev Build to TestFlight Internal Testing
# This script builds the dev release IPA and uploads it to TestFlight internal testing

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "🔨 Building iOS Dev Release IPA..."

# Bump build number
echo "📱 Bumping build number..."
chmod +x scripts/auto-bump-build.sh scripts/get-version.sh
./scripts/auto-bump-build.sh
echo "✅ Version bumped to: $(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
echo ""

# Load environment variables
set -a
source "$PROJECT_DIR/.env"
set +a

# Set environment
export ENVIRONMENT=dev

# Export iOS-specific environment variables for Fastlane
export APP_STORE_CONNECT_API_KEY_KEY_ID
export APP_STORE_CONNECT_API_KEY_ISSUER_ID
export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH
export IOS_BUNDLE_ID
export APPLE_TEAM_ID
export MATCH_PASSWORD
export MATCH_GCS_BUCKET
export MATCH_GCS_PROJECT_ID

# Build the IPA using Flutter
echo "📦 Building IPA (dev release)..."
flutter build ipa \
    --release \
    --dart-define=ENVIRONMENT=dev \
    --export-options-plist=ios/ExportOptions.plist

echo "✅ Build complete!"
echo "📍 IPA location: build/ios/ipa/"
echo ""

# Upload to TestFlight Internal Testing
echo "☁️  Uploading to TestFlight Internal Testing..."
cd ios

# Check if bundle install is needed
if [ ! -f "Gemfile.lock" ] || [ "Gemfile" -nt "Gemfile.lock" ]; then
    echo "📦 Installing/updating Fastlane dependencies..."
    bundle install
    echo "✅ Dependencies installed"
fi

# Use upload_ipa_only lane since Flutter already built and signed the IPA
# This avoids needing Match/GCP credentials for local builds
bundle exec fastlane upload_ipa_only

echo ""
echo "🎉 Dev build deployed to TestFlight Internal Testing!"
echo "   View at: https://appstoreconnect.apple.com"
