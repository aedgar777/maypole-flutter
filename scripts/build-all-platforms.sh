#!/bin/bash

# Comprehensive build script for all platforms and environments

echo "🚀 Maypole Multi-Platform Build Script"
echo "========================================"
echo ""
echo "Available build targets:"
echo ""
echo "ANDROID:"
echo "  1. Android Dev Debug APK"
echo "  2. Android Dev Release APK"
echo "  3. Android Prod Debug APK"
echo "  4. Android Prod Release APK"
echo "  5. Android Prod Release Bundle (AAB)"
echo ""
echo "IOS:"
echo "  6. iOS Dev Debug"
echo "  7. iOS Dev Release"
echo "  8. iOS Prod Debug"
echo "  9. iOS Prod Release"
echo " 10. iOS Dev IPA"
echo " 11. iOS Prod IPA"
echo ""
echo "MACOS:"
echo " 12. macOS Dev Debug"
echo " 13. macOS Dev Release"
echo " 14. macOS Prod Debug"
echo " 15. macOS Prod Release"
echo " 16. macOS Dev DMG"
echo " 17. macOS Prod DMG"
echo ""
echo "WEB:"
echo " 18. Web Dev"
echo " 19. Web Prod"
echo ""
echo " 0. Exit"
echo ""

read -p "Select build target (0-19): " choice

case $choice in
    1)
        echo "Building Android Dev Debug APK..."
        ./scripts/build-android-dev-debug.sh
        ;;
    2)
        echo "Building Android Dev Release APK..."
        ./scripts/build-android-dev-release.sh
        ;;
    3)
        echo "Building Android Prod Debug APK..."
        ./scripts/build-android-prod-debug.sh
        ;;
    4)
        echo "Building Android Prod Release APK..."
        ./scripts/build-android-prod-release.sh
        ;;
    5)
        echo "Building Android Prod Release Bundle (AAB)..."
        ./scripts/build-android-bundle.sh
        ;;
    6)
        echo "Building iOS Dev Debug..."
        ./scripts/build-ios-dev-debug.sh
        ;;
    7)
        echo "Building iOS Dev Release..."
        ./scripts/build-ios-dev-release.sh
        ;;
    8)
        echo "Building iOS Prod Debug..."
        ./scripts/build-ios-prod-debug.sh
        ;;
    9)
        echo "Building iOS Prod Release..."
        ./scripts/build-ios-prod-release.sh
        ;;
    10)
        echo "Building iOS Dev IPA..."
        ./scripts/build-ios-ipa-dev.sh
        ;;
    11)
        echo "Building iOS Prod IPA..."
        ./scripts/build-ios-ipa-prod.sh
        ;;
    12)
        echo "Building macOS Dev Debug..."
        ./scripts/build-macos-dev-debug.sh
        ;;
    13)
        echo "Building macOS Dev Release..."
        ./scripts/build-macos-dev-release.sh
        ;;
    14)
        echo "Building macOS Prod Debug..."
        ./scripts/build-macos-prod-debug.sh
        ;;
    15)
        echo "Building macOS Prod Release..."
        ./scripts/build-macos-prod-release.sh
        ;;
    16)
        echo "Building macOS Dev DMG..."
        ./scripts/build-macos-dmg-dev.sh
        ;;
    17)
        echo "Building macOS Prod DMG..."
        ./scripts/build-macos-dmg-prod.sh
        ;;
    18)
        echo "Building Web Dev..."
        ./scripts/build-web-dev.sh
        ;;
    19)
        echo "Building Web Prod..."
        ./scripts/build-web-prod.sh
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "❌ Invalid selection"
        exit 1
        ;;
esac
