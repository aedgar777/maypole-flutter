#!/bin/bash

# Script to quickly test AdMob integration
# Usage: ./scripts/test-admob.sh

set -e

echo "🧪 Testing AdMob Integration..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Flutter is in PATH
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found in PATH${NC}"
    echo "Adding Flutter to PATH for this session..."
    export PATH="$PATH:/home/andrewedgar/Development/flutter/bin"
    
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Error: Could not find Flutter${NC}"
        echo "Please ensure Flutter is installed at /home/andrewedgar/Development/flutter/"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Flutter found${NC}"
flutter --version | head -1
echo ""

# Verify AdMob files exist
echo "📁 Checking AdMob files..."
FILES=(
    "lib/core/ads/ad_config.dart"
    "lib/core/ads/ad_service.dart"
    "lib/core/ads/ad_providers.dart"
    "lib/core/ads/widgets/banner_ad_widget.dart"
    "lib/core/ads/widgets/interstitial_ad_manager.dart"
    "lib/core/ads/widgets/rewarded_ad_manager.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $file"
    else
        echo -e "${RED}❌${NC} $file (missing!)"
        exit 1
    fi
done
echo ""

# Check pubspec.yaml for google_mobile_ads
echo "📦 Checking dependencies..."
if grep -q "google_mobile_ads:" pubspec.yaml; then
    echo -e "${GREEN}✅ google_mobile_ads dependency found${NC}"
else
    echo -e "${RED}❌ google_mobile_ads not in pubspec.yaml${NC}"
    exit 1
fi
echo ""

# Run flutter pub get
echo "📥 Running flutter pub get..."
flutter pub get > /dev/null 2>&1
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Analyze the AdMob code
echo "🔍 Analyzing AdMob code..."
if flutter analyze lib/core/ads/ lib/main.dart --no-fatal-infos 2>&1 | grep -q "No issues found"; then
    echo -e "${GREEN}✅ No issues found!${NC}"
else
    echo -e "${YELLOW}⚠️  Some issues found:${NC}"
    flutter analyze lib/core/ads/ lib/main.dart --no-fatal-infos
fi
echo ""

# Check configuration
echo "⚙️  Checking configuration..."
if grep -q "static const bool adsEnabled = true" lib/core/ads/ad_config.dart; then
    echo -e "${GREEN}✅ Ads enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Ads disabled${NC}"
fi

if grep -q "static const bool useTestAds = true" lib/core/ads/ad_config.dart; then
    echo -e "${GREEN}✅ Using test ads (safe for development)${NC}"
else
    echo -e "${YELLOW}⚠️  Using production ads${NC}"
fi
echo ""

# Check Android manifest
echo "📱 Checking Android configuration..."
if grep -q "com.google.android.gms.ads.APPLICATION_ID" android/app/src/main/AndroidManifest.xml; then
    echo -e "${GREEN}✅ Android AdMob App ID configured${NC}"
else
    echo -e "${RED}❌ Android AdMob App ID missing${NC}"
fi
echo ""

# Check iOS plist
echo "🍎 Checking iOS configuration..."
if grep -q "GADApplicationIdentifier" ios/Runner/Info.plist; then
    echo -e "${GREEN}✅ iOS AdMob App ID configured${NC}"
else
    echo -e "${RED}❌ iOS AdMob App ID missing${NC}"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 AdMob Integration Test Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Run 'flutter run' to test on a device"
echo "2. Look for: ✅ AdMob SDK initialized successfully"
echo "3. See ADMOB_PLACEMENT_EXAMPLES.md to add ads to your UI"
echo ""
echo "Documentation:"
echo "- ADMOB_COMPLETE_SUMMARY.md - Start here!"
echo "- ADMOB_INTEGRATION.md - Complete reference"
echo "- ADMOB_PLACEMENT_EXAMPLES.md - Code examples"
echo "- ADMOB_AD_PLACEMENT_GUIDE.md - Visual guide"
echo ""
