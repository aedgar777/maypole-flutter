#!/bin/bash

# Verify Build Configurations
echo "🔍 Verifying Build Configurations..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track errors
ERRORS=0

# Check Android Build Variants
echo "📱 Checking Android Build Variants..."
if [ -f "android/gradlew" ]; then
    ANDROID_VARIANTS=$(./android/gradlew -p android app:tasks --all 2>&1 | grep "^assemble" | grep -E "(devDebug|devRelease|prodDebug|prodRelease)" | grep -v "AndroidTest\|UnitTest" | wc -l)
    
    if [ "$ANDROID_VARIANTS" -eq 4 ]; then
        echo -e "  ${GREEN}✓${NC} Found all 4 Android build variants"
        ./android/gradlew -p android app:tasks --all 2>&1 | grep "^assemble" | grep -E "(devDebug|devRelease|prodDebug|prodRelease)" | grep -v "AndroidTest\|UnitTest" | sed 's/^/    /'
    else
        echo -e "  ${RED}✗${NC} Expected 4 Android build variants, found $ANDROID_VARIANTS"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "  ${RED}✗${NC} android/gradlew not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Android Build Configuration
echo "📄 Checking Android build.gradle.kts..."
if grep -q "flavorDimensions" android/app/build.gradle.kts && \
   grep -q "create(\"dev\")" android/app/build.gradle.kts && \
   grep -q "create(\"prod\")" android/app/build.gradle.kts; then
    echo -e "  ${GREEN}✓${NC} Product flavors configured correctly"
else
    echo -e "  ${RED}✗${NC} Product flavors not configured"
    ERRORS=$((ERRORS + 1))
fi

if grep -q "buildTypes {" android/app/build.gradle.kts && \
   grep -q "debug {" android/app/build.gradle.kts && \
   grep -q "release {" android/app/build.gradle.kts; then
    echo -e "  ${GREEN}✓${NC} Build types configured correctly"
else
    echo -e "  ${RED}✗${NC} Build types not configured"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Android Manifests
echo "📋 Checking Android Manifests..."
if [ -f "android/app/src/dev/AndroidManifest.xml" ]; then
    echo -e "  ${GREEN}✓${NC} Dev flavor manifest exists"
else
    echo -e "  ${RED}✗${NC} Dev flavor manifest missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "android/app/src/prod/AndroidManifest.xml" ]; then
    echo -e "  ${GREEN}✓${NC} Prod flavor manifest exists"
else
    echo -e "  ${RED}✗${NC} Prod flavor manifest missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Android Firebase configs
echo "🔥 Checking Android Firebase Configurations..."
if [ -f "android/app/src/dev/google-services.json" ]; then
    echo -e "  ${GREEN}✓${NC} Dev google-services.json exists"
else
    echo -e "  ${YELLOW}⚠${NC}  Dev google-services.json missing (may need to be added)"
fi

if [ -f "android/app/src/prod/google-services.json" ]; then
    echo -e "  ${GREEN}✓${NC} Prod google-services.json exists"
else
    echo -e "  ${YELLOW}⚠${NC}  Prod google-services.json missing (may need to be added)"
fi
echo ""

# Check iOS Build Configurations
echo "🍎 Checking iOS Build Configurations..."
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    IOS_CONFIGS=$(grep -o "name = \"dev-debug\|name = \"dev-release\|name = \"prod-debug\|name = \"prod-release" ios/Runner.xcodeproj/project.pbxproj | wc -l)
    
    if [ "$IOS_CONFIGS" -ge 4 ]; then
        echo -e "  ${GREEN}✓${NC} Found iOS build configurations"
        grep -o "name = \"dev-debug\"\|name = \"dev-release\"\|name = \"prod-debug\"\|name = \"prod-release\"" ios/Runner.xcodeproj/project.pbxproj | sort -u | sed 's/name = /    /'
    else
        echo -e "  ${RED}✗${NC} iOS build configurations incomplete"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "  ${RED}✗${NC} iOS project file not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Build Scripts
echo "📜 Checking Build Scripts..."
SCRIPTS=("build-android-dev-debug.sh" "build-android-dev-release.sh" "build-android-prod-debug.sh" "build-android-prod-release.sh" "build-android-bundle.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "scripts/$script" ] && [ -x "scripts/$script" ]; then
        echo -e "  ${GREEN}✓${NC} scripts/$script exists and is executable"
    elif [ -f "scripts/$script" ]; then
        echo -e "  ${YELLOW}⚠${NC}  scripts/$script exists but not executable"
        chmod +x "scripts/$script"
        echo -e "     ${GREEN}✓${NC} Made executable"
    else
        echo -e "  ${RED}✗${NC} scripts/$script missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check Documentation
echo "📖 Checking Documentation..."
DOCS=("ANDROID_BUILD_CONFIGURATIONS.md" "BUILD_CONFIGURATIONS_SUMMARY.md" "QUICK_START_BUILD_CONFIGS.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "  ${GREEN}✓${NC} $doc exists"
    else
        echo -e "  ${YELLOW}⚠${NC}  $doc missing"
    fi
done
echo ""

# Summary
echo "═══════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All build configurations verified successfully!${NC}"
    echo ""
    echo "You can now:"
    echo "  • Use Build Variants panel in Android Studio"
    echo "  • Select build configurations in Xcode"
    echo "  • Run build scripts from scripts/ directory"
    echo ""
    echo "Quick start: See QUICK_START_BUILD_CONFIGS.md"
    exit 0
else
    echo -e "${RED}❌ Found $ERRORS error(s) in build configuration${NC}"
    echo ""
    echo "Please review the errors above and fix them."
    echo "See BUILD_CONFIGURATIONS_SUMMARY.md for setup instructions."
    exit 1
fi
