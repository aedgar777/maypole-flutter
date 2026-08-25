#!/bin/bash

# Build iOS Dev Release
echo "🔨 Building iOS Dev Release..."

# Set environment
export ENVIRONMENT=dev

# Build the app
echo "📦 Building iOS app..."
flutter build ios \
    --release \
    --flavor dev \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo ""
echo "To run on device:"
echo "  flutter install -d <device-id> --release --flavor dev --dart-define=ENVIRONMENT=dev"
