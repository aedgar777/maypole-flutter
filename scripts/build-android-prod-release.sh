#!/bin/bash

# Build Android Prod Release
echo "🔨 Building Android Prod Release..."

# Set environment
export ENVIRONMENT=production

# Build the app
echo "📦 Building APK..."
flutter build apk \
    --release \
    --flavor prod \
    --dart-define=ENVIRONMENT=production

echo "✅ Build complete!"
echo "📍 APK location: build/app/outputs/flutter-apk/app-prod-release.apk"
echo ""
echo "To install on device:"
echo "  flutter install --release --flavor prod"
