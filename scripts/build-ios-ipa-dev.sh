#!/bin/bash

# Build iOS IPA for Dev Environment
echo "🔨 Building iOS IPA (Dev)..."

# Set environment
export ENVIRONMENT=dev

# Build the IPA
echo "📦 Building IPA..."
flutter build ipa \
    --release \
    --flavor dev \
    --dart-define=ENVIRONMENT=dev

echo "✅ Build complete!"
echo "📍 IPA location: build/ios/ipa/"
echo ""
echo "To upload to TestFlight:"
echo "  xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa --username <your-apple-id> --password <app-specific-password>"
