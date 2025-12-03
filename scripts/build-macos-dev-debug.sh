#!/bin/bash

# Build macOS Dev Debug
echo "🔨 Building macOS Dev Debug..."

# Set environment
export ENVIRONMENT=dev

# Build the app
echo "📦 Building macOS app..."
flutter build macos \
    --debug \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo "📍 App location: build/macos/Build/Products/Debug/maypole.app"
echo ""
echo "To run:"
echo "  open build/macos/Build/Products/Debug/maypole.app"
echo "  OR"
echo "  flutter run -d macos --debug --dart-define=ENVIRONMENT=dev"
