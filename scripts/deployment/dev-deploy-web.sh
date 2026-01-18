#!/bin/bash

# Deploy Web Dev Build to Firebase Hosting
# This script builds the dev web app and deploys it to Firebase hosting

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "🌐 Building and deploying Web Dev to Firebase Hosting..."

# Bump build number
echo "📱 Bumping build number..."
chmod +x scripts/auto-bump-build.sh scripts/get-version.sh
./scripts/auto-bump-build.sh
echo "✅ Version bumped to: $(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
echo ""

# Load environment variables
set -a
source "$(dirname "$0")/../../.env"
set +a

# Build the web app
echo "📦 Building web app (dev)..."
flutter build web \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=FIREBASE_DEV_WEB_API_KEY="${FIREBASE_DEV_WEB_API_KEY}" \
  --dart-define=FIREBASE_DEV_WEB_APP_ID="${FIREBASE_DEV_WEB_APP_ID}" \
  --dart-define=FIREBASE_DEV_MESSAGING_SENDER_ID="${FIREBASE_DEV_MESSAGING_SENDER_ID}" \
  --dart-define=FIREBASE_DEV_PROJECT_ID="${FIREBASE_DEV_PROJECT_ID}" \
  --dart-define=FIREBASE_DEV_AUTH_DOMAIN="${FIREBASE_DEV_AUTH_DOMAIN}" \
  --dart-define=FIREBASE_DEV_STORAGE_BUCKET="${FIREBASE_DEV_STORAGE_BUCKET}" \
  --dart-define=FIREBASE_DEV_WEB_MEASUREMENT_ID="${FIREBASE_DEV_WEB_MEASUREMENT_ID}" \
  --dart-define=GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_DEV_API_KEY}"

echo "✅ Build complete!"
echo ""

# Copy deeplink verification files to build directory
echo "🔗 Copying deeplink verification files..."
mkdir -p build/web/.well-known

# Copy Apple App Site Association files
cp public/apple-app-site-association build/web/apple-app-site-association
cp public/.well-known/apple-app-site-association build/web/.well-known/apple-app-site-association

# Copy Android Asset Links file
cp public/.well-known/assetlinks.json build/web/.well-known/assetlinks.json

echo "✅ Verification files copied!"
echo ""

# Deploy to Firebase Hosting
echo "☁️  Deploying to Firebase Hosting (dev)..."
firebase deploy --only hosting --project maypole-flutter-dev

echo ""
echo "🎉 Web app deployed to Firebase Hosting!"
echo "   View at: https://maypole-flutter-dev.web.app"
echo ""
echo "🔗 Deeplink verification files deployed:"
echo "   - https://maypole-flutter-dev.web.app/apple-app-site-association"
echo "   - https://maypole-flutter-dev.web.app/.well-known/assetlinks.json"
