#!/bin/bash

# Fix Android Toolchain Issues
# This script installs missing Android cmdline-tools and accepts licenses

set -e  # Exit on error

echo "🔧 Fixing Android Toolchain..."
echo ""

# Set up Java - Always use Android Studio's bundled JDK for consistency
if [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "☕ Using Android Studio's bundled JDK at: $JAVA_HOME"
elif [ -d "/Applications/Android Studio.app/Contents/jre/Contents/Home" ]; then
    export JAVA_HOME="/Applications/Android Studio.app/Contents/jre/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "☕ Using Android Studio's bundled JRE at: $JAVA_HOME"
else
    echo "❌ Error: Android Studio's JDK not found"
    echo "   Please install Android Studio or set JAVA_HOME manually"
    exit 1
fi

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
CMDLINE_TOOLS_DIR="$ANDROID_SDK_ROOT/cmdline-tools"
LATEST_DIR="$CMDLINE_TOOLS_DIR/latest"

# Check if Android SDK exists
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "❌ Error: Android SDK not found at $ANDROID_SDK_ROOT"
    echo "   Please install Android Studio first"
    exit 1
fi

echo "📍 Android SDK found at: $ANDROID_SDK_ROOT"
echo ""

# Install cmdline-tools if missing
if [ ! -d "$LATEST_DIR" ]; then
    echo "📦 Installing Android cmdline-tools..."
    
    # Create cmdline-tools directory
    mkdir -p "$CMDLINE_TOOLS_DIR"
    
    # Download cmdline-tools
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
    TEMP_ZIP="/tmp/cmdline-tools.zip"
    
    echo "⬇️  Downloading cmdline-tools..."
    curl -L -o "$TEMP_ZIP" "$CMDLINE_TOOLS_URL"
    
    echo "📂 Extracting cmdline-tools..."
    unzip -q "$TEMP_ZIP" -d "$CMDLINE_TOOLS_DIR"
    
    # Move to 'latest' directory (required directory structure)
    mv "$CMDLINE_TOOLS_DIR/cmdline-tools" "$LATEST_DIR"
    
    # Clean up
    rm "$TEMP_ZIP"
    
    echo "✅ cmdline-tools installed successfully!"
else
    echo "✅ cmdline-tools already installed"
fi

echo ""

# Update PATH for this session
export PATH="$LATEST_DIR/bin:$PATH"

# Accept Android licenses
echo "📜 Accepting Android SDK licenses..."
yes | "$LATEST_DIR/bin/sdkmanager" --licenses 2>&1 | grep -v "Warning:" || true

echo ""
echo "✅ Android toolchain fixed!"
echo ""
echo "Run 'flutter doctor' to verify the fix"
