#!/bin/bash

# Build macOS DMG for Dev Environment
echo "🔨 Building macOS DMG (Dev)..."

# Set environment
export ENVIRONMENT=dev

# First build the app
echo "📦 Building macOS app..."
flutter build macos \
    --release \
    --dart-define=ENVIRONMENT=dev

APP_PATH="build/macos/Build/Products/Release/maypole.app"
DMG_NAME="Maypole-Dev-macOS.dmg"
VOLUME_NAME="Maypole Dev"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    exit 1
fi

echo "📦 Creating DMG..."
# Create a temporary directory for DMG contents
TMP_DIR="build/macos/dmg_temp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Copy the app to temp directory
cp -R "$APP_PATH" "$TMP_DIR/"

# Create the DMG
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TMP_DIR" \
    -ov -format UDZO \
    "build/macos/$DMG_NAME"

# Clean up
rm -rf "$TMP_DIR"

echo "✅ Build complete!"
echo "📍 DMG location: build/macos/$DMG_NAME"
