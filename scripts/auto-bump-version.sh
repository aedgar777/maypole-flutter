#!/bin/bash

# Automatically bump version (for deployment scripts)
# This script increments version without prompts
# Usage: ./scripts/auto-bump-version.sh [major|minor|patch|build]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

# Check if bump type is provided
if [ $# -eq 0 ]; then
    echo "Error: Bump type not specified"
    echo "Usage: $0 [major|minor|patch|build]"
    exit 1
fi

BUMP_TYPE="$1"

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch|build)$ ]]; then
    echo "Error: Invalid bump type '$BUMP_TYPE'"
    echo "Valid types: major, minor, patch, build"
    exit 1
fi

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

# Extract version components
MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3)

# Calculate new version based on bump type
case $BUMP_TYPE in
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_MINOR=0
        NEW_PATCH=0
        NEW_BUILD=$((BUILD_NUMBER + 1))
        ;;
    minor)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$((MINOR + 1))
        NEW_PATCH=0
        NEW_BUILD=$((BUILD_NUMBER + 1))
        ;;
    patch)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$MINOR
        NEW_PATCH=$((PATCH + 1))
        NEW_BUILD=$((BUILD_NUMBER + 1))
        ;;
    build)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$MINOR
        NEW_PATCH=$PATCH
        NEW_BUILD=$((BUILD_NUMBER + 1))
        ;;
esac

NEW_VERSION_NAME="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD"

echo "Auto-bumping version ($BUMP_TYPE)..."
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

if [ "$BUMP_TYPE" != "build" ]; then
    echo "✅ Version bumped: $VERSION_NAME → $NEW_VERSION_NAME (build $BUILD_NUMBER → $NEW_BUILD)"
else
    echo "✅ Build number bumped: $BUILD_NUMBER → $NEW_BUILD"
fi

# Export for use in scripts
export NEW_VERSION="$NEW_VERSION"
export NEW_VERSION_NAME="$NEW_VERSION_NAME"
export NEW_BUILD_NUMBER="$NEW_BUILD"
