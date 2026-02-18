#!/bin/bash

# Deploy Web Production Build to Firebase Hosting
# This script builds the prod web app and deploys it to Firebase hosting in production

set -e  # Exit on error

echo "🌐 Building and deploying Web Production to Firebase Hosting..."

# Load environment variables
set -a
source "$(dirname "$0")/../../.env"
set +a

# Build the web app with prod configuration
echo "📦 Building web app (production)..."
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

# Copy ads.txt file for AdSense
echo "📱 Copying ads.txt for AdSense..."
cp web/ads.txt build/web/ads.txt
echo "✅ ads.txt copied!"
echo ""

# Deploy to Firebase Hosting production
echo "☁️  Deploying to Firebase Hosting (production)..."
firebase deploy --only hosting --project maypole-flutter-ce6c3

echo ""
echo "🎉 Web app deployed to Production Firebase Hosting!"
echo "   View at: https://maypole.app"
echo ""
echo "🔗 Verification files deployed:"
echo "   - https://maypole.app/apple-app-site-association"
echo "   - https://maypole.app/.well-known/assetlinks.json"
echo "   - https://maypole.app/ads.txt"
echo ""
echo "📊 Production Console:"
echo "   https://console.firebase.google.com/project/maypole-flutter-ce6c3"
