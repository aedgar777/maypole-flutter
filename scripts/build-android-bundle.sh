#!/bin/bash

# Build Android App Bundle for Play Store
echo "🔨 Building Android App Bundle..."

# Check which environment to build
ENVIRONMENT=${1:-production}

if [ "$ENVIRONMENT" == "dev" ]; then
    FLAVOR="dev"
    echo "📦 Building Dev App Bundle..."
else
    FLAVOR="prod"
    echo "📦 Building Production App Bundle..."
fi

# Build the app bundle
flutter build appbundle \
    --release \
    --flavor "$FLAVOR" \
    --dart-define=ENVIRONMENT="$ENVIRONMENT"

echo "✅ Build complete!"
echo "📍 AAB location: build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
echo ""
echo "This bundle can be uploaded to Google Play Console"
