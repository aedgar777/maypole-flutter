#!/bin/bash

# Load environment variables from .env
set -a
source .env
set +a

echo "🌐 Building Flutter Web for DEV environment..."

flutter build web \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=FIREBASE_DEV_WEB_API_KEY="${FIREBASE_DEV_WEB_API_KEY}" \
  --dart-define=FIREBASE_DEV_WEB_APP_ID="${FIREBASE_DEV_WEB_APP_ID}" \
  --dart-define=FIREBASE_DEV_MESSAGING_SENDER_ID="${FIREBASE_DEV_MESSAGING_SENDER_ID}" \
  --dart-define=FIREBASE_DEV_PROJECT_ID="${FIREBASE_DEV_PROJECT_ID}" \
  --dart-define=FIREBASE_DEV_AUTH_DOMAIN="${FIREBASE_DEV_AUTH_DOMAIN}" \
  --dart-define=FIREBASE_DEV_STORAGE_BUCKET="${FIREBASE_DEV_STORAGE_BUCKET}" \
  --dart-define=FIREBASE_DEV_WEB_MEASUREMENT_ID="${FIREBASE_DEV_WEB_MEASUREMENT_ID}" \
  --dart-define=GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_DEV_API_KEY}" \
  --dart-define=CLOUD_FUNCTIONS_URL="${CLOUD_FUNCTIONS_DEV_URL}"

echo "✅ Web build complete!"
echo ""

# Copy ads.txt file for AdSense
echo "📱 Copying ads.txt for AdSense..."
cp web/ads.txt build/web/ads.txt
echo "✅ ads.txt copied!"
echo ""
echo "Deploy with: firebase deploy --only hosting"
