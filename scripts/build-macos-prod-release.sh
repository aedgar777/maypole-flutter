#!/bin/bash

# Build macOS Prod Release
echo "🔨 Building macOS Prod Release..."

# Set environment
export ENVIRONMENT=prod

# Build the app
echo "📦 Building macOS app..."
flutter build macos \
    --release \
    --dart-define=ENVIRONMENT=prod

echo "✅ Build complete!"
echo "📍 App location: build/macos/Build/Products/Release/maypole.app"
echo ""
echo "To run:"
echo "  open build/macos/Build/Products/Release/maypole.app"
echo "  OR"
echo "  flutter run -d macos --release --dart-define=ENVIRONMENT=prod"
