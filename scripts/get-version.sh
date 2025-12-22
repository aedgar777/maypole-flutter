#!/bin/bash

# Get current version from pubspec.yaml
# Usage: ./scripts/get-version.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC"
    exit 1
fi

# Extract version line from pubspec.yaml
VERSION_LINE=$(grep "^version:" "$PUBSPEC" | head -n 1)

if [ -z "$VERSION_LINE" ]; then
    echo "Error: Could not find version in pubspec.yaml"
    exit 1
fi

# Extract full version (e.g., "1.0.0+1")
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | tr -d ' ')

# Extract version name (e.g., "1.0.0")
VERSION_NAME=$(echo "$FULL_VERSION" | cut -d'+' -f1)

# Extract build number (e.g., "1")
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

# Extract individual version components
MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3)

# Display version information
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Current Version Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Full Version:    $FULL_VERSION"
echo "Version Name:    $VERSION_NAME"
echo "Build Number:    $BUILD_NUMBER"
echo ""
echo "Components:"
echo "  Major:         $MAJOR"
echo "  Minor:         $MINOR"
echo "  Patch:         $PATCH"
echo "  Build:         $BUILD_NUMBER"
echo ""
echo "Platform Mapping:"
echo "  Android:"
echo "    versionName: $VERSION_NAME"
echo "    versionCode: $BUILD_NUMBER"
echo "  iOS:"
echo "    CFBundleShortVersionString: $VERSION_NAME"
echo "    CFBundleVersion: $BUILD_NUMBER"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Export variables for use in other scripts
export CURRENT_VERSION="$FULL_VERSION"
export CURRENT_VERSION_NAME="$VERSION_NAME"
export CURRENT_BUILD_NUMBER="$BUILD_NUMBER"
export CURRENT_MAJOR="$MAJOR"
export CURRENT_MINOR="$MINOR"
export CURRENT_PATCH="$PATCH"
