#!/bin/bash
# All-in-one script: sets up environment and builds iOS
# Usage: ./scripts/build-ios.sh

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Setting up environment and building iOS..."
echo ""

# Source the setup script
source "$SCRIPT_DIR/setup-local-env.sh"

echo ""
echo "🚀 Starting iOS build..."
echo ""

# Run the build script
"$SCRIPT_DIR/local-ios-build.sh"
