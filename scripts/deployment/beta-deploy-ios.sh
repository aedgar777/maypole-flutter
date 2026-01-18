#!/bin/bash

# Deploy iOS Beta Build to TestFlight Beta Testing
# This script builds the prod release IPA (with prod config) and uploads it to TestFlight beta testing

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "🔨 Building iOS Beta (Prod Config) Release IPA..."

# Bump patch version
echo "📱 Bumping patch version..."
chmod +x scripts/auto-bump-version.sh scripts/get-version.sh
./scripts/auto-bump-version.sh patch
echo "✅ Version bumped to: $(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
echo ""

# Load environment variables
set -a
source "$(dirname "$0")/../../.env"
set +a

# Validate Google Cloud credentials for Match
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ Error: GOOGLE_APPLICATION_CREDENTIALS not set in .env"
    exit 1
fi

if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ Error: Google Cloud credentials file not found at: $GOOGLE_APPLICATION_CREDENTIALS"
    exit 1
fi

echo "✅ Google Cloud credentials found: $GOOGLE_APPLICATION_CREDENTIALS"
echo ""

# Set environment to prod (beta uses prod configuration)
export ENVIRONMENT=production

# Build the IPA using Flutter with prod configuration
echo "📦 Building IPA (prod release for beta)..."
flutter build ipa \
    --release \
    --dart-define=ENVIRONMENT=production \
    --export-options-plist=ios/ExportOptions.plist

echo "✅ Build complete!"
echo "📍 IPA location: build/ios/ipa/"
echo ""

# Upload to TestFlight Beta Testing
echo "☁️  Uploading to TestFlight Beta Testing..."
cd ios
bundle exec fastlane deploy_beta

echo ""
echo "🎉 Beta build deployed to TestFlight Beta Testing!"
echo "   View at: https://appstoreconnect.apple.com"
echo ""
echo "Note: Beta testers will be notified via TestFlight."
