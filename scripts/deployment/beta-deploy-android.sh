#!/bin/bash

# Deploy Android Beta Build to Play Store Open Testing Track
# This script builds the prod release AAB (with prod config) and uploads it to Play Store open testing

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "🔨 Building Android Beta (Prod Config) Release AAB..."

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

# Set environment to prod (beta uses prod configuration)
export ENVIRONMENT=prod

# Build the Android App Bundle with prod flavor
echo "📦 Building Android App Bundle (prod release for beta)..."
flutter build appbundle \
    --release \
    --flavor prod \
    --dart-define=ENVIRONMENT=prod

echo "✅ Build complete!"
echo "📍 AAB location: build/app/outputs/bundle/prodRelease/app-prod-release.aab"
echo ""

# Upload to Play Store Open Testing
echo "☁️  Uploading to Play Store Open Testing (Beta) track..."
cd android
bundle exec fastlane deploy_beta_open

echo ""
echo "🎉 Beta build uploaded to Play Store Open Testing as DRAFT!"
echo "   View at: https://play.google.com/console"
echo ""
echo "📋 Next steps:"
echo "   1. Go to Play Console → Release → Testing → Open testing"
echo "   2. Review the release"
echo "   3. Publish the release to make it available to testers"
echo ""
echo "⚠️  Note: If upload fails with 'draft app' error:"
echo "   • Delete the existing draft release in Play Console first"
echo "   • Or publish the existing draft, then upload a new one"
