#!/bin/bash

# Build iOS Prod Release
echo "🔨 Building iOS Prod Release..."

# Set environment
export ENVIRONMENT=prod

# Build the app
echo "📦 Building iOS app..."
flutter build ios \
    --release \
    --dart-define=ENVIRONMENT=prod

echo "✅ Build complete!"
echo ""
echo "To install on device:"
echo "  flutter install -d <device-id> --release --dart-define=ENVIRONMENT=prod"
echo ""
echo "To build IPA for distribution:"
echo "  flutter build ipa --release --dart-define=ENVIRONMENT=prod"
