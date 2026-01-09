#!/bin/bash

# Build iOS IPA for Prod Environment
echo "🔨 Building iOS IPA (Prod)..."

# Set environment
export ENVIRONMENT=prod

# Build the IPA
echo "📦 Building IPA..."
flutter build ipa \
    --release \
    --dart-define=ENVIRONMENT=prod

echo "✅ Build complete!"
echo "📍 IPA location: build/ios/ipa/"
echo ""
echo "To upload to TestFlight:"
echo "  xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa --username <your-apple-id> --password <app-specific-password>"
