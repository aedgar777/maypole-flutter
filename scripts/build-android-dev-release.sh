#!/bin/bash

# Build Android Dev Release
echo "🔨 Building Android Dev Release..."

# Set environment
export ENVIRONMENT=dev

# Build the app
echo "📦 Building APK..."
flutter build apk \
    --release \
    --flavor dev \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo "📍 APK location: build/app/outputs/flutter-apk/app-dev-release.apk"
echo ""
echo "To install on device:"
echo "  flutter install --release --flavor dev"
