#!/bin/bash

# Build macOS Prod Debug
echo "🔨 Building macOS Prod Debug..."

# Set environment
export ENVIRONMENT=prod

# Build the app
echo "📦 Building macOS app..."
flutter build macos \
    --debug \
    --dart-define=ENVIRONMENT=prod

echo "✅ Build complete!"
echo "📍 App location: build/macos/Build/Products/Debug/maypole.app"
echo ""
echo "To run:"
echo "  open build/macos/Build/Products/Debug/maypole.app"
echo "  OR"
echo "  flutter run -d macos --debug --dart-define=ENVIRONMENT=prod"
