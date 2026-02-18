#!/bin/bash

# Manually copy ads.txt to build directory
# Use this if you need to ensure ads.txt is in place without doing a full build

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "📱 Copying ads.txt to build directory..."

# Ensure build/web directory exists
if [ ! -d "build/web" ]; then
    echo "❌ Error: build/web directory does not exist"
    echo "   Run 'flutter build web' first"
    exit 1
fi

# Check if source ads.txt exists
if [ ! -f "web/ads.txt" ]; then
    echo "❌ Error: web/ads.txt does not exist"
    echo "   Create the file first with your AdSense publisher ID"
    exit 1
fi

# Copy the file
cp web/ads.txt build/web/ads.txt

echo "✅ ads.txt copied successfully!"
echo ""
echo "File contents:"
cat build/web/ads.txt
echo ""
echo "📤 You can now deploy with: firebase deploy --only hosting"
