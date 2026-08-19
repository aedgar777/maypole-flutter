#!/bin/bash

# Build iOS Prod Debug
echo "🔨 Building iOS Prod Debug..."

# Set environment
export ENVIRONMENT=prod

# Build the app
echo "📦 Building iOS app..."
flutter build ios \
    --debug \
    --flavor prod \
    --dart-define=ENVIRONMENT=prod

echo "✅ Build complete!"
echo ""
echo "To run on simulator/device:"
echo "  flutter run -d <device-id> --debug --flavor prod --dart-define=ENVIRONMENT=prod"
