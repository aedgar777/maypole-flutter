#!/bin/bash

# Deploy All Beta Builds (Android, iOS, Web)
# This script:
# 1. Bumps patch version for beta release
# 2. Builds and deploys Android to Play Store Open Testing
# 3. Builds and deploys iOS to TestFlight Beta Testing
# 4. Builds and deploys Web to Firebase Hosting Beta Channel

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Maypole Beta Full Deployment                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Bump patch version
echo "📊 Bumping patch version for beta release..."
echo "════════════════════════════════════════════════════════════"
bash "$PROJECT_DIR/scripts/auto-bump-version.sh" patch

echo ""

# Step 2: Deploy Android
echo "🤖 Deploying Android to Play Store Open Testing..."
echo "════════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/beta-deploy-android.sh"

echo ""
echo "✅ Android deployed!"
echo ""

# Step 3: Deploy iOS
echo "🍎 Deploying iOS to TestFlight Beta Testing..."
echo "════════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/beta-deploy-ios.sh"

echo ""
echo "✅ iOS deployed!"
echo ""

# Step 4: Deploy Web
echo "🌐 Deploying Web to Firebase Hosting Beta Channel..."
echo "════════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/beta-deploy-web.sh"

echo ""
echo "✅ Web deployed!"
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🎉 All Beta Deployments Complete!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 Android: Play Store Open Testing (Beta Track)"
echo "   https://play.google.com/console"
echo ""
echo "🍎 iOS: TestFlight Beta Testing"
echo "   https://appstoreconnect.apple.com"
echo ""
echo "🌐 Web: Firebase Hosting Beta Channel"
echo "   Check Firebase Console for beta channel URL"
echo ""
