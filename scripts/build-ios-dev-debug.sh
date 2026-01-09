#!/bin/bash

# Build iOS Dev Debug
echo "🔨 Building iOS Dev Debug..."

# Set environment
export ENVIRONMENT=dev

# Build the app
echo "📦 Building iOS app..."
flutter build ios \
    --debug \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo ""
echo "To run on simulator/device:"
echo "  flutter run -d <device-id> --debug --dart-define=ENVIRONMENT=dev"
