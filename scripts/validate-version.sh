#!/bin/bash

# Validate version format in pubspec.yaml
# Usage: ./scripts/validate-version.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Version Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found${NC}"
    exit 1
fi

# Get current version
VERSION_LINE=$(grep "^version:" "$PUBSPEC" | head -n 1)

if [ -z "$VERSION_LINE" ]; then
    echo -e "${RED}❌ Error: No version found in pubspec.yaml${NC}"
    exit 1
fi

CURRENT_VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | tr -d ' ')

echo "Current version: $CURRENT_VERSION"
echo ""

# Validate format: MAJOR.MINOR.PATCH+BUILD
if ! [[ "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
    echo -e "${RED}❌ Invalid version format${NC}"
    echo ""
    echo "Expected format: MAJOR.MINOR.PATCH+BUILD"
    echo "Example: 1.0.0+1"
    echo ""
    echo "Your version: $CURRENT_VERSION"
    exit 1
fi

# Extract components
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3)

echo "Validation checks:"
echo ""

# Check 1: Version components are numbers
VALID=true

if ! [[ "$MAJOR" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Major version must be a number${NC}"
    VALID=false
else
    echo -e "${GREEN}✅ Major version is valid: $MAJOR${NC}"
fi

if ! [[ "$MINOR" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Minor version must be a number${NC}"
    VALID=false
else
    echo -e "${GREEN}✅ Minor version is valid: $MINOR${NC}"
fi

if ! [[ "$PATCH" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Patch version must be a number${NC}"
    VALID=false
else
    echo -e "${GREEN}✅ Patch version is valid: $PATCH${NC}"
fi

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Build number must be a number${NC}"
    VALID=false
else
    echo -e "${GREEN}✅ Build number is valid: $BUILD_NUMBER${NC}"
fi

# Check 2: Build number is positive
if [ "$BUILD_NUMBER" -lt 1 ]; then
    echo -e "${YELLOW}⚠️  Warning: Build number should be at least 1${NC}"
fi

# Check 3: Version name components are reasonable
if [ "$MAJOR" -gt 100 ]; then
    echo -e "${YELLOW}⚠️  Warning: Major version seems unusually high${NC}"
fi

if [ "$MINOR" -gt 100 ]; then
    echo -e "${YELLOW}⚠️  Warning: Minor version seems unusually high${NC}"
fi

if [ "$PATCH" -gt 100 ]; then
    echo -e "${YELLOW}⚠️  Warning: Patch version seems unusually high${NC}"
fi

echo ""

if [ "$VALID" = true ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Version format is valid!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ Version validation failed${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
