#!/bin/bash

# Build Android Prod Debug
echo "🔨 Building Android Prod Debug..."

# Set environment
export ENVIRONMENT=production

# Build the app
echo "📦 Building APK..."
flutter build apk \
    --debug \
    --flavor prod \
    --dart-define=ENVIRONMENT=production

echo "✅ Build complete!"
echo "📍 APK location: build/app/outputs/flutter-apk/app-prod-debug.apk"
echo ""
echo "To install on device:"
echo "  flutter install --debug --flavor prod"
