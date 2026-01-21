#!/bin/bash

# Deploy Web Beta Build to Firebase Hosting (Beta Site)
# This script builds the prod web app and deploys it to Firebase hosting beta site

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "🌐 Building and deploying Web Beta to Firebase Hosting..."

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

# Build the web app with prod configuration
echo "📦 Building web app (prod config for beta)..."
flutter build web \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=FIREBASE_PROD_WEB_API_KEY="${FIREBASE_PROD_WEB_API_KEY}" \
  --dart-define=FIREBASE_PROD_WEB_APP_ID="${FIREBASE_PROD_WEB_APP_ID}" \
  --dart-define=FIREBASE_PROD_MESSAGING_SENDER_ID="${FIREBASE_PROD_MESSAGING_SENDER_ID}" \
  --dart-define=FIREBASE_PROD_PROJECT_ID="${FIREBASE_PROD_PROJECT_ID}" \
  --dart-define=FIREBASE_PROD_AUTH_DOMAIN="${FIREBASE_PROD_AUTH_DOMAIN}" \
  --dart-define=FIREBASE_PROD_STORAGE_BUCKET="${FIREBASE_PROD_STORAGE_BUCKET}" \
  --dart-define=FIREBASE_PROD_WEB_MEASUREMENT_ID="${FIREBASE_PROD_WEB_MEASUREMENT_ID}" \
  --dart-define=GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_PROD_API_KEY}" \
  --dart-define=CLOUD_FUNCTIONS_URL="${CLOUD_FUNCTIONS_PROD_URL}"

echo "✅ Build complete!"
echo ""

# Deploy to Firebase Hosting beta site
# Note: You need to set up a beta hosting site first using:
#   firebase hosting:channel:create beta --project maypole-flutter-ce6c3
echo "☁️  Deploying to Firebase Hosting beta site..."

# Check if beta channel exists, if not create it
if ! firebase hosting:channel:list --project maypole-flutter-ce6c3 2>/dev/null | grep -q "beta"; then
    echo "Creating beta hosting channel..."
    firebase hosting:channel:create beta --project maypole-flutter-ce6c3
fi

firebase hosting:channel:deploy beta --project maypole-flutter-ce6c3

echo ""
echo "🎉 Web beta deployed to Firebase Hosting!"
echo "   View at: https://maypole-flutter-ce6c3--beta-<channel-id>.web.app"
echo ""
echo "Note: To get the exact URL, check the Firebase Console or the output above."
