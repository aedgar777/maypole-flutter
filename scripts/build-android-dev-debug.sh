#!/bin/bash

# Build Android Dev Debug
echo "🔨 Building Android Dev Debug..."

# Set environment
export ENVIRONMENT=dev

# Build the app
echo "📦 Building APK..."
flutter build apk \
    --debug \
    --flavor dev \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo "📍 APK location: build/app/outputs/flutter-apk/app-dev-debug.apk"
echo ""
echo "To install on device:"
echo "  flutter install --debug --flavor dev"
