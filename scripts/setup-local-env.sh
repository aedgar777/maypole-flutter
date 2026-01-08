#!/bin/bash
# Source this script to set up your local environment for iOS builds
# Usage: source scripts/setup-local-env.sh

echo "🔧 Setting up local iOS build environment..."

# Get the script directory - handle both when sourced and when executed
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
    SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
fi

# Get project root (parent of scripts directory)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📂 Project root: $PROJECT_ROOT"

# Setup rbenv if available
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init - zsh)" 2>/dev/null || eval "$(rbenv init - bash)" 2>/dev/null || true
    export PATH="$HOME/.rbenv/shims:$PATH"
    echo "✅ rbenv initialized"
fi

# Load .env file
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "✅ Loading variables from .env..."
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo "❌ .env file not found"
    return 1
fi

# Export the .p8 file content
if [ -f "$HOME/Downloads/AuthKey_YTL9X357KS.p8" ]; then
    export APP_STORE_CONNECT_API_KEY_CONTENT="$(cat $HOME/Downloads/AuthKey_YTL9X357KS.p8)"
    echo "✅ App Store Connect API key loaded"
elif [ -f "$HOME/Documents/apple-keys/AuthKey_YTL9X357KS.p8" ]; then
    export APP_STORE_CONNECT_API_KEY_CONTENT="$(cat $HOME/Documents/apple-keys/AuthKey_YTL9X357KS.p8)"
    echo "✅ App Store Connect API key loaded"
else
    echo "⚠️  AuthKey_YTL9X357KS.p8 not found in Downloads or Documents/apple-keys"
fi

# Export the GCP service account key
if [ -f "$HOME/Downloads/maypole-flutter-ce6c3-990dc1013cda.json" ]; then
    export GCP_SERVICE_ACCOUNT_KEY="$(cat $HOME/Downloads/maypole-flutter-ce6c3-990dc1013cda.json)"
    export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/maypole-flutter-ce6c3-990dc1013cda.json"
    echo "✅ GCP service account key loaded"
else
    echo "⚠️  GCP service account JSON not found in Downloads"
fi

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "You can now run:"
echo "  ./scripts/local-ios-build.sh"
echo ""
