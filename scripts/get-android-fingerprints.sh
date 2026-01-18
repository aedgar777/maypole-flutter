#!/bin/bash

# Script to get Android SHA-256 fingerprints for App Links setup

echo "=========================================="
echo "Android SHA-256 Fingerprint Extraction"
echo "=========================================="
echo ""

# Debug keystore
echo "1. DEBUG KEYSTORE"
echo "----------------------------------------"
if [ -f ~/.android/debug.keystore ]; then
    echo "Debug keystore found. Extracting SHA-256..."
    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -A1 "SHA256" | grep "SHA256"
else
    echo "⚠️  Debug keystore not found at ~/.android/debug.keystore"
fi
echo ""

# Release keystore
echo "2. RELEASE KEYSTORE"
echo "----------------------------------------"
echo "To get your release keystore SHA-256, run:"
echo ""
echo "  keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias"
echo ""
echo "Or get it from Google Play Console:"
echo "  → Play Console → Your App → Release → Setup → App Integrity"
echo "  → Copy 'SHA-256 certificate fingerprint'"
echo ""

# Instructions
echo "=========================================="
echo "NEXT STEPS:"
echo "=========================================="
echo ""
echo "1. Copy the SHA-256 fingerprints above"
echo ""
echo "2. Update web_assets/assetlinks.json:"
echo "   - Replace REPLACE_WITH_YOUR_DEBUG_SHA256_FINGERPRINT"
echo "   - Replace REPLACE_WITH_YOUR_RELEASE_SHA256_FINGERPRINT"
echo ""
echo "3. Format: Remove colons and make uppercase"
echo "   Example: AA:BB:CC... → AABBCC..."
echo ""
echo "4. Deploy to your web server at:"
echo "   https://maypole.app/.well-known/assetlinks.json"
echo "   https://maypole-flutter-dev.web.app/.well-known/assetlinks.json"
echo ""
