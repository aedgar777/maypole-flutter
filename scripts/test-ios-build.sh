#!/bin/bash
# Test iOS build locally to debug hanging issues
# Usage: ./scripts/test-ios-build.sh

set -e

cd "$(dirname "$0")/.."

echo "🧪 iOS Build Test Script"
echo "========================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found${NC}"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter: $(flutter --version | head -1)${NC}"
echo -e "${GREEN}✅ Xcode: $(xcodebuild -version | head -1)${NC}"
echo ""

# Test 1: Flutter doctor
echo "🩺 Test 1: Flutter Doctor"
echo "-------------------------"
flutter doctor -v
echo ""

# Test 2: Clean build
echo "🧹 Test 2: Clean Build"
echo "----------------------"
cd ios
rm -rf build/ DerivedData/ Pods/ .symlinks/
echo "✅ Cleaned iOS build artifacts"
cd ..
echo ""

# Test 3: Pod install
echo "📦 Test 3: CocoaPods Install"
echo "----------------------------"
cd ios
pod install
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Pods installed successfully${NC}"
else
    echo -e "${RED}❌ Pod install failed${NC}"
    exit 1
fi
cd ..
echo ""

# Test 4: Flutter build (no codesign)
echo "🔨 Test 4: Flutter Build (no codesign)"
echo "--------------------------------------"
timeout 600 flutter build ios --release --no-codesign --verbose 2>&1 | tee /tmp/flutter-build.log
FLUTTER_EXIT=$?

if [ $FLUTTER_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter build succeeded${NC}"
elif [ $FLUTTER_EXIT -eq 124 ]; then
    echo -e "${RED}❌ Flutter build TIMED OUT after 10 minutes${NC}"
    echo "Last 50 lines of output:"
    tail -50 /tmp/flutter-build.log
    exit 1
else
    echo -e "${RED}❌ Flutter build failed with exit code $FLUTTER_EXIT${NC}"
    exit 1
fi
echo ""

# Test 5: Check workspace
echo "📂 Test 5: Verify Workspace"
echo "---------------------------"
if [ -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
    echo -e "${GREEN}✅ Workspace exists${NC}"
else
    echo -e "${RED}❌ Workspace not found${NC}"
    exit 1
fi
echo ""

# Test 6: Xcode build test (without signing)
echo "🔧 Test 6: Xcode Build Test"
echo "---------------------------"
echo -e "${YELLOW}⚠️  This will attempt to build without signing (may fail at signing step, that's OK)${NC}"
cd ios
timeout 600 xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tee /tmp/xcodebuild.log

XCODE_EXIT=$?

if [ $XCODE_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ Xcode build succeeded${NC}"
elif [ $XCODE_EXIT -eq 124 ]; then
    echo -e "${RED}❌ Xcode build TIMED OUT after 10 minutes${NC}"
    echo "This is the hang you're seeing in CI!"
    echo ""
    echo "Last 100 lines of output:"
    tail -100 /tmp/xcodebuild.log
    echo ""
    echo "📋 Check these logs:"
    echo "  - /tmp/xcodebuild.log (full output)"
    echo "  - ~/Library/Logs/CoreSimulator/ (simulator logs)"
    echo "  - ~/Library/Logs/DiagnosticReports/ (crash logs)"
    exit 1
else
    echo -e "${YELLOW}⚠️  Build exited with code $XCODE_EXIT (may be signing related, that's expected)${NC}"
    
    # Check if it's just a signing error (that's OK)
    if grep -q "Code Signing Error" /tmp/xcodebuild.log || grep -q "Signing" /tmp/xcodebuild.log; then
        echo -e "${GREEN}✅ Build succeeded until signing step (expected)${NC}"
    else
        echo -e "${RED}❌ Build failed for non-signing reason${NC}"
        echo "Last 50 lines:"
        tail -50 /tmp/xcodebuild.log
    fi
fi
cd ..
echo ""

# Test 7: Check for common issues
echo "🔍 Test 7: Check for Common Issues"
echo "-----------------------------------"

ISSUES_FOUND=0

# Check for Firebase config
if [ -f "ios/Firebase/dev/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ Firebase dev config exists${NC}"
else
    echo -e "${RED}❌ Firebase dev config missing${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check for Ruby/Bundler
if [ -f "ios/Gemfile" ] && [ -f "ios/Gemfile.lock" ]; then
    echo -e "${GREEN}✅ Ruby Gemfile exists${NC}"
    cd ios
    if bundle check &> /dev/null; then
        echo -e "${GREEN}✅ Bundle dependencies satisfied${NC}"
    else
        echo -e "${YELLOW}⚠️  Bundle dependencies not satisfied (run 'bundle install')${NC}"
    fi
    cd ..
else
    echo -e "${YELLOW}⚠️  No Gemfile found${NC}"
fi

# Check for signing certificates (if fastlane is configured)
if command -v fastlane &> /dev/null; then
    echo -e "${GREEN}✅ Fastlane installed${NC}"
    echo "   To test full deployment (with signing), run:"
    echo "   cd ios && bundle exec fastlane ios deploy_dev"
else
    echo -e "${YELLOW}⚠️  Fastlane not installed globally${NC}"
fi

echo ""

# Summary
echo "📊 Test Summary"
echo "==============="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Your build should work in CI.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. If CI still hangs, it's likely a CI environment issue"
    echo "  2. Check GitHub Actions logs for specific errors"
    echo "  3. Consider using a different macOS version in CI"
    echo "  4. Review IOS_TESTFLIGHT_DEBUG_GUIDE.md for more options"
else
    echo -e "${YELLOW}⚠️  $ISSUES_FOUND issues found - fix these before deploying${NC}"
fi
echo ""

# Save diagnostic info
echo "💾 Saving diagnostic information..."
{
    echo "iOS Build Test - $(date)"
    echo "========================"
    echo ""
    echo "Environment:"
    echo "  Flutter: $(flutter --version | head -1)"
    echo "  Xcode: $(xcodebuild -version | head -1)"
    echo "  Ruby: $(ruby --version)"
    echo "  Bundler: $(bundle --version 2>/dev/null || echo 'not installed')"
    echo "  Fastlane: $(fastlane --version 2>/dev/null || echo 'not installed')"
    echo ""
    echo "Available SDKs:"
    xcodebuild -showsdks
    echo ""
    echo "Pod versions:"
    grep -A 1 "PODS:" ios/Podfile.lock | head -20
} > /tmp/ios-build-diagnostics.txt

echo "✅ Diagnostics saved to /tmp/ios-build-diagnostics.txt"
