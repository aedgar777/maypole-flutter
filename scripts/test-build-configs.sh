#!/bin/bash

# Test script to verify all build configurations are working

echo "🧪 Testing Build Configurations"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASS=0
FAIL=0

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found: $1"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} Missing: $1"
        ((FAIL++))
        return 1
    fi
}

# Function to check if a script is executable
check_executable() {
    if [ -x "$1" ]; then
        echo -e "${GREEN}✓${NC} Executable: $1"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} Not executable: $1"
        ((FAIL++))
        return 1
    fi
}

echo "1️⃣  Checking Android Build Scripts..."
echo "-----------------------------------"
check_file "scripts/build-android-dev-debug.sh"
check_executable "scripts/build-android-dev-debug.sh"
check_file "scripts/build-android-dev-release.sh"
check_executable "scripts/build-android-dev-release.sh"
check_file "scripts/build-android-prod-debug.sh"
check_executable "scripts/build-android-prod-debug.sh"
check_file "scripts/build-android-prod-release.sh"
check_executable "scripts/build-android-prod-release.sh"
check_file "scripts/build-android-bundle.sh"
check_executable "scripts/build-android-bundle.sh"
echo ""

echo "2️⃣  Checking iOS Build Scripts..."
echo "-------------------------------"
check_file "scripts/build-ios-dev-debug.sh"
check_executable "scripts/build-ios-dev-debug.sh"
check_file "scripts/build-ios-dev-release.sh"
check_executable "scripts/build-ios-dev-release.sh"
check_file "scripts/build-ios-prod-debug.sh"
check_executable "scripts/build-ios-prod-debug.sh"
check_file "scripts/build-ios-prod-release.sh"
check_executable "scripts/build-ios-prod-release.sh"
check_file "scripts/build-ios-ipa-dev.sh"
check_executable "scripts/build-ios-ipa-dev.sh"
check_file "scripts/build-ios-ipa-prod.sh"
check_executable "scripts/build-ios-ipa-prod.sh"
echo ""

echo "3️⃣  Checking macOS Build Scripts..."
echo "---------------------------------"
check_file "scripts/build-macos-dev-debug.sh"
check_executable "scripts/build-macos-dev-debug.sh"
check_file "scripts/build-macos-dev-release.sh"
check_executable "scripts/build-macos-dev-release.sh"
check_file "scripts/build-macos-prod-debug.sh"
check_executable "scripts/build-macos-prod-debug.sh"
check_file "scripts/build-macos-prod-release.sh"
check_executable "scripts/build-macos-prod-release.sh"
check_file "scripts/build-macos-dmg-dev.sh"
check_executable "scripts/build-macos-dmg-dev.sh"
check_file "scripts/build-macos-dmg-prod.sh"
check_executable "scripts/build-macos-dmg-prod.sh"
echo ""

echo "4️⃣  Checking Web Build Scripts..."
echo "-------------------------------"
check_file "scripts/build-web-dev.sh"
check_executable "scripts/build-web-dev.sh"
check_file "scripts/build-web-prod.sh"
check_executable "scripts/build-web-prod.sh"
echo ""

echo "5️⃣  Checking Utility Scripts..."
echo "-----------------------------"
check_file "scripts/build-all-platforms.sh"
check_executable "scripts/build-all-platforms.sh"
check_file "scripts/switch-to-dev.sh"
check_executable "scripts/switch-to-dev.sh"
check_file "scripts/switch-to-prod.sh"
check_executable "scripts/switch-to-prod.sh"
check_file "scripts/validate-env.sh"
check_executable "scripts/validate-env.sh"
check_file "scripts/verify-build-configs.sh"
check_executable "scripts/verify-build-configs.sh"
echo ""

echo "6️⃣  Checking iOS Configuration Files..."
echo "-------------------------------------"
check_file "ios/Flutter/Dev-Debug.xcconfig"
check_file "ios/Flutter/Dev-Release.xcconfig"
check_file "ios/Flutter/Prod-Debug.xcconfig"
check_file "ios/Flutter/Prod-Release.xcconfig"
check_file "ios/Runner.xcodeproj/project.pbxproj"
echo ""

echo "7️⃣  Checking macOS Configuration Files..."
echo "---------------------------------------"
check_file "macos/Runner/Configs/Dev-Debug.xcconfig"
check_file "macos/Runner/Configs/Dev-Release.xcconfig"
check_file "macos/Runner/Configs/Prod-Debug.xcconfig"
check_file "macos/Runner/Configs/Prod-Release.xcconfig"
check_file "macos/Runner.xcodeproj/project.pbxproj"
echo ""

echo "8️⃣  Checking Documentation..."
echo "---------------------------"
check_file "docs/BUILDING_IOS_MACOS.md"
check_file "scripts/README.md"
check_file "scripts/QUICK_START.md"
echo ""

echo "9️⃣  Testing Flutter Setup..."
echo "--------------------------"
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✓${NC} Flutter is installed"
    ((PASS++))
    
    # Check Flutter doctor
    echo ""
    echo "Running flutter doctor..."
    flutter doctor
else
    echo -e "${RED}✗${NC} Flutter is not installed or not in PATH"
    ((FAIL++))
fi
echo ""

echo "🔟 Testing Xcode Setup (macOS only)..."
echo "------------------------------------"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v xcodebuild &> /dev/null; then
        echo -e "${GREEN}✓${NC} Xcode command-line tools installed"
        ((PASS++))
        xcodebuild -version
    else
        echo -e "${RED}✗${NC} Xcode command-line tools not installed"
        echo "Run: xcode-select --install"
        ((FAIL++))
    fi
    
    # Check for CocoaPods
    if command -v pod &> /dev/null; then
        echo -e "${GREEN}✓${NC} CocoaPods installed"
        ((PASS++))
        pod --version
    else
        echo -e "${YELLOW}⚠${NC} CocoaPods not installed (needed for iOS/macOS)"
        echo "Run: sudo gem install cocoapods"
        ((FAIL++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Not running on macOS - skipping Xcode checks"
fi
echo ""

echo "================================"
echo "📊 Test Results"
echo "================================"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "🚀 You're ready to build for all platforms!"
    echo ""
    echo "Quick start:"
    echo "  - Android Studio: Select device → Click Run"
    echo "  - Terminal: ./scripts/build-all-platforms.sh"
    echo "  - iOS: flutter run -d ios --dart-define=ENVIRONMENT=dev"
    echo "  - macOS: flutter run -d macos --dart-define=ENVIRONMENT=prod"
    exit 0
else
    echo -e "${RED}❌ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above and run this script again."
    exit 1
fi
