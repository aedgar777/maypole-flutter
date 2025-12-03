#!/bin/bash

# Build macOS Dev Release
echo "🔨 Building macOS Dev Release..."

# Set environment
export ENVIRONMENT=dev

# Build the app
echo "📦 Building macOS app..."
flutter build macos \
    --release \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo "📍 App location: build/macos/Build/Products/Release/maypole.app"
echo ""
echo "To run:"
echo "  open build/macos/Build/Products/Release/maypole.app"
echo "  OR"
echo "  flutter run -d macos --release --dart-define=ENVIRONMENT=dev"
