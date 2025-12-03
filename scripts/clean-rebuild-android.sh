#!/bin/bash
# Clean rebuild script for Android to ensure splash screen changes are applied

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🗑️ Removing Android build cache..."
rm -rf android/app/build
rm -rf android/build
rm -rf android/.gradle

echo "🔨 Building Android APK..."
flutter build apk --debug --flavor dev

echo "✅ Clean build complete!"
echo ""
echo "To install on connected device, run:"
echo "  flutter install --debug --flavor dev"
