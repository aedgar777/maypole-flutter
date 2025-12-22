#!/bin/bash

# Bump version in pubspec.yaml
# Usage: ./scripts/bump-version.sh [major|minor|patch|build]
#
# Examples:
#   ./scripts/bump-version.sh patch  # 1.0.0+1 → 1.0.1+2
#   ./scripts/bump-version.sh minor  # 1.0.0+1 → 1.1.0+2
#   ./scripts/bump-version.sh major  # 1.0.0+1 → 2.0.0+2
#   ./scripts/bump-version.sh build  # 1.0.0+1 → 1.0.0+2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if bump type is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Bump type not specified${NC}"
    echo ""
    echo "Usage: $0 [major|minor|patch|build]"
    echo ""
    echo "Examples:"
    echo "  $0 patch  # 1.0.0+1 → 1.0.1+2"
    echo "  $0 minor  # 1.0.0+1 → 1.1.0+2"
    echo "  $0 major  # 1.0.0+1 → 2.0.0+2"
    echo "  $0 build  # 1.0.0+1 → 1.0.0+2 (build number only)"
    exit 1
fi

BUMP_TYPE="$1"

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch|build)$ ]]; then
    echo -e "${RED}Error: Invalid bump type '$BUMP_TYPE'${NC}"
    echo "Valid types: major, minor, patch, build"
    exit 1
fi

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
    echo -e "${RED}Error: pubspec.yaml not found at $PUBSPEC${NC}"
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

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔄 Version Bump Tool${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Current Version: ${YELLOW}$CURRENT_VERSION${NC}"
echo ""

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

echo -e "Bump Type:       ${GREEN}$BUMP_TYPE${NC}"
echo -e "New Version:     ${GREEN}$NEW_VERSION${NC}"
echo ""

# Show what changed
if [ "$BUMP_TYPE" != "build" ]; then
    echo "Changes:"
    echo "  Version Name: $VERSION_NAME → $NEW_VERSION_NAME"
    echo "  Build Number: $BUILD_NUMBER → $NEW_BUILD"
else
    echo "Changes:"
    echo "  Build Number: $BUILD_NUMBER → $NEW_BUILD (version name unchanged)"
fi
echo ""

# Ask for confirmation
read -p "Proceed with version bump? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Version bump cancelled${NC}"
    exit 0
fi

# Create backup of pubspec.yaml
cp "$PUBSPEC" "$PUBSPEC.backup"
echo "Created backup: pubspec.yaml.backup"

# Update version in pubspec.yaml
sed -i.tmp "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
rm "$PUBSPEC.tmp" 2>/dev/null || true

echo -e "${GREEN}✅ Version updated successfully!${NC}"
echo ""
echo "Updated file: pubspec.yaml"
echo "Old version:  $CURRENT_VERSION"
echo "New version:  $NEW_VERSION"
echo ""

# Ask if user wants to commit the change
read -p "Commit this change to git? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if git is available
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Git not found, skipping commit${NC}"
        exit 0
    fi
    
    # Check if this is a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${YELLOW}Not a git repository, skipping commit${NC}"
        exit 0
    fi
    
    # Commit the change
    git add "$PUBSPEC"
    git commit -m "chore: bump version to $NEW_VERSION"
    
    echo -e "${GREEN}✅ Changes committed${NC}"
    echo ""
    
    # Ask if user wants to create a git tag
    read -p "Create git tag v$NEW_VERSION_NAME? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -a "v$NEW_VERSION_NAME" -m "Release version $NEW_VERSION_NAME"
        echo -e "${GREEN}✅ Tag created: v$NEW_VERSION_NAME${NC}"
        echo ""
        echo "Remember to push the tag:"
        echo "  git push origin v$NEW_VERSION_NAME"
    fi
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Done!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
