#!/bin/bash

# Automatically bump build number (for CI/CD use)
# This script increments only the build number, leaving version name unchanged
# Usage: ./scripts/auto-bump-build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC"
    exit 1
fi

# Get current version
VERSION_LINE=$(grep "^version:" "$PUBSPEC" | head -n 1)
CURRENT_VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Calculate new build number
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD"

echo "Auto-bumping build number..."
echo "Current: $CURRENT_VERSION"
echo "New:     $NEW_VERSION"

# Update version in pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
else
    # Linux
    sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
fi

echo "✅ Build number bumped: $BUILD_NUMBER → $NEW_BUILD"
echo "New version: $NEW_VERSION"

# Export for use in CI/CD
export NEW_VERSION="$NEW_VERSION"
export NEW_BUILD_NUMBER="$NEW_BUILD"
