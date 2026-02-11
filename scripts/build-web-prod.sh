#!/bin/bash

# Load environment variables from .env
set -a
source .env
set +a

echo "🌐 Building Flutter Web for PRODUCTION environment..."

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

echo "✅ Web build complete!"
echo ""

# Copy ads.txt file for AdSense
echo "📱 Copying ads.txt for AdSense..."
cp web/ads.txt build/web/ads.txt
echo "✅ ads.txt copied!"
echo ""
echo "Deploy with: firebase deploy --only hosting"
