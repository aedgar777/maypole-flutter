#!/bin/bash

# Deploy All Dev Builds (Android, iOS, Web) with Tests
# This script:
# 1. Runs unit tests (exits if they fail)
# 2. Deploys all Firebase tools to maypole-flutter-dev
# 3. Builds and deploys Android to Play Store Internal Testing
# 4. Builds and deploys iOS to TestFlight Internal Testing
# 5. Builds and deploys Web to Firebase Hosting

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Maypole Dev Full Deployment                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Run unit tests
echo "🧪 Running unit tests..."
echo "════════════════════════════════════════════════════════════"
cd "$PROJECT_DIR"
if ! flutter test; then
    echo ""
    echo "❌ Unit tests failed! Deployment cancelled."
    echo "   Please fix the failing tests and try again."
    exit 1
fi

echo ""
echo "✅ All tests passed!"
echo ""

# Step 2: Bump build number
echo "📊 Bumping build number..."
echo "════════════════════════════════════════════════════════════"
bash "$PROJECT_DIR/scripts/auto-bump-build.sh"

echo ""

# Step 3: Deploy Firebase tools
echo "☁️  Deploying Firebase tools to maypole-flutter-dev..."
echo "════════════════════════════════════════════════════════════"
firebase deploy \
    --only firestore:rules,firestore:indexes,storage,functions \
    --project maypole-flutter-dev

echo ""
echo "✅ Firebase tools deployed!"
echo ""

# Step 4: Deploy Android
echo "🤖 Deploying Android to Play Store Internal Testing..."
echo "════════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/dev-deploy-android.sh"

echo ""
echo "✅ Android deployed!"
echo ""

# Step 5: Deploy iOS
echo "🍎 Deploying iOS to TestFlight Internal Testing..."
echo "════════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/dev-deploy-ios.sh"

echo ""
echo "✅ iOS deployed!"
echo ""

# Step 6: Deploy Web
echo "🌐 Deploying Web to Firebase Hosting..."
echo "════════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/dev-deploy-web.sh"

echo ""
echo "✅ Web deployed!"
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🎉 All Dev Deployments Complete!                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 Android: Play Store Internal Testing"
echo "   https://play.google.com/console"
echo ""
echo "🍎 iOS: TestFlight Internal Testing"
echo "   https://appstoreconnect.apple.com"
echo ""
echo "🌐 Web: Firebase Hosting"
echo "   https://maypole-flutter-dev.web.app"
echo ""
