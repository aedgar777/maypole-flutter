#!/bin/bash
set -e

# Linux Build Setup Script
# This script helps you set up Linux development support for Maypole

echo "========================================"
echo "Maypole Flutter - Linux Build Setup"
echo "========================================"
echo ""

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script is intended for Linux systems only."
    echo "   Current OS: $OSTYPE"
    exit 1
fi

echo "This script will:"
echo "  1. Install Linux build dependencies"
echo "  2. Enable Flutter Linux desktop support"
echo "  3. Verify the setup"
echo "  4. Test a build"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "Step 1: Installing Linux build dependencies..."
echo "--------------------------------------------"

# Detect package manager
if command -v apt-get &> /dev/null; then
    echo "Detected apt-get (Ubuntu/Debian)"
    sudo apt-get update -y
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
elif command -v dnf &> /dev/null; then
    echo "Detected dnf (Fedora/RHEL)"
    sudo dnf install -y clang cmake ninja-build gtk3-devel pkgconf-pkg-config
elif command -v pacman &> /dev/null; then
    echo "Detected pacman (Arch Linux)"
    sudo pacman -S --noconfirm clang cmake ninja gtk3 pkgconf
else
    echo "⚠️  Could not detect package manager."
    echo "   Please install these packages manually:"
    echo "   - clang"
    echo "   - cmake"
    echo "   - ninja-build"
    echo "   - pkg-config"
    echo "   - libgtk-3-dev (or gtk3-devel)"
    echo ""
    read -p "Have you installed these manually? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "✅ Dependencies installed"
echo ""

echo "Step 2: Enabling Flutter Linux desktop support..."
echo "--------------------------------------------------"
flutter config --enable-linux-desktop
echo ""
echo "✅ Linux desktop support enabled"
echo ""

echo "Step 3: Verifying setup..."
echo "-----------------------------"
echo ""
flutter doctor
echo ""

# Check if Linux toolchain is enabled
if flutter doctor | grep -q "Linux toolchain"; then
    echo "✅ Linux toolchain detected"
else
    echo "⚠️  Linux toolchain not fully configured"
    echo "   Run 'flutter doctor' for details"
fi

echo ""
echo "Step 4: Getting Flutter dependencies..."
echo "----------------------------------------"
flutter pub get
echo ""
echo "✅ Dependencies fetched"
echo ""

echo "Step 5: Testing a build..."
echo "--------------------------"
read -p "Would you like to test a Linux build now? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Building Linux debug version..."
    flutter build linux --debug
    
    if [ -f "build/linux/x64/debug/bundle/maypole" ]; then
        echo ""
        echo "✅ Build successful!"
        echo ""
        echo "You can run the app with:"
        echo "  ./build/linux/x64/debug/bundle/maypole"
        echo ""
        read -p "Would you like to run it now? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./build/linux/x64/debug/bundle/maypole
        fi
    else
        echo "❌ Build failed. Check the output above for errors."
        exit 1
    fi
else
    echo "Skipping test build."
fi

echo ""
echo "========================================"
echo "🎉 Linux build setup complete!"
echo "========================================"
echo ""
echo "Quick reference:"
echo "  • Build scripts: ./scripts/build-linux-*.sh"
echo "  • Quick start: docs/LINUX_QUICK_START.md"
echo "  • Full guide: docs/LINUX_BUILD_GUIDE.md"
echo "  • Checklist: docs/LINUX_BUILD_CHECKLIST.md"
echo ""
echo "To build for development:"
echo "  ./scripts/build-linux-dev-release.sh"
echo ""
echo "To run during development:"
echo "  flutter run -d linux"
echo ""
echo "Happy coding! 🚀"
echo ""
