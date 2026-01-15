#!/bin/bash
set -e  # Exit on error

echo "=========================================="
echo "Test xcodebuild Archive & Export"
echo "=========================================="
echo ""
echo "This script assumes:"
echo "  1. Flutter has already built the app"
echo "  2. Certificates are already synced"
echo "  3. You just want to test the archive & export"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables from .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "✅ Loading environment from .env..."
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -v '^$' | xargs)
else
    echo "❌ .env file not found at $PROJECT_ROOT/.env"
    exit 1
fi

# Load .env.local if it exists (for secrets - this file is gitignored)
if [ -f "$PROJECT_ROOT/.env.local" ]; then
    echo "✅ Loading secrets from .env.local..."
    export $(grep -v '^#' "$PROJECT_ROOT/.env.local" | grep -v '^$' | xargs)
else
    echo "⚠️  .env.local not found - you'll need to export secrets manually"
    echo "   See .env.local.example for what you need"
fi

# Check if Flutter build exists
if [ ! -d "$PROJECT_ROOT/build/ios/Release-iphoneos/Runner.app" ]; then
    echo "❌ Flutter build not found. Run first:"
    echo "   flutter build ios --release --no-codesign"
    exit 1
fi

echo "✅ Flutter build found"
echo ""

# Check for required environment variables
if [ -z "$APPLE_TEAM_ID" ]; then
    echo "❌ APPLE_TEAM_ID not set. Export it first:"
    echo "   export APPLE_TEAM_ID='your-team-id'"
    exit 1
fi

if [ -z "$IOS_BUNDLE_ID" ]; then
    echo "❌ IOS_BUNDLE_ID not set in .env"
    exit 1
fi

echo "Team ID: $APPLE_TEAM_ID"
echo "Bundle ID: $IOS_BUNDLE_ID"
echo ""

# Navigate to iOS directory
cd "$PROJECT_ROOT/ios"

ARCHIVE_PATH="$PROJECT_ROOT/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$PROJECT_ROOT/build/ios/ipa"

echo "=========================================="
echo "Step 1: Create Archive"
echo "=========================================="
echo ""
echo "This will show ALL xcodebuild output..."
echo ""

# Remove old archive if it exists
rm -rf "$ARCHIVE_PATH"
mkdir -p "$(dirname "$ARCHIVE_PATH")"

# Run xcodebuild archive with FULL output (no -quiet)
xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  archive \
  CODE_SIGN_ONLY=YES

echo ""
echo "✅ Archive created at: $ARCHIVE_PATH"
echo ""

echo "=========================================="
echo "Step 2: Create ExportOptions.plist"
echo "=========================================="

PROFILE_NAME="match AppStore ${IOS_BUNDLE_ID}"
EXPORT_OPTIONS="/tmp/ExportOptions.plist"

cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${IOS_BUNDLE_ID}</key>
        <string>${PROFILE_NAME}</string>
    </dict>
    <key>signingStyle</key>
    <string>manual</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ ExportOptions.plist created at: $EXPORT_OPTIONS"
echo ""
echo "Contents:"
cat "$EXPORT_OPTIONS"
echo ""

echo "=========================================="
echo "Step 3: Export IPA"
echo "=========================================="
echo ""

# Remove old export if it exists
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

# Run xcodebuild export with FULL output (no -quiet)
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates

echo ""
echo "✅ IPA exported to: $EXPORT_DIR/Runner.ipa"
echo ""

# Show IPA info
if [ -f "$EXPORT_DIR/Runner.ipa" ]; then
    echo "=========================================="
    echo "IPA Details"
    echo "=========================================="
    ls -lh "$EXPORT_DIR/Runner.ipa"
    echo ""
    echo "✅ SUCCESS! IPA is ready."
else
    echo "❌ IPA file not found at $EXPORT_DIR/Runner.ipa"
    exit 1
fi
