#!/bin/bash

# Setup Cloud Functions for Firebase
# This script sets up the Python virtual environment and installs dependencies

set -e

echo "🔧 Setting up Firebase Cloud Functions..."
echo ""

# Check if python3-venv is installed
if ! dpkg -l | grep -q python3.*-venv; then
    echo "⚠️  python3-venv is not installed"
    echo "   Run: sudo apt install python3.12-venv"
    echo ""
    read -p "Would you like to install it now? (requires sudo) [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt install python3.12-venv
    else
        echo "❌ Cannot continue without python3-venv"
        exit 1
    fi
fi

# Navigate to functions directory
cd "$(dirname "$0")/../functions" || exit 1

echo "📁 Working directory: $(pwd)"
echo ""

# Remove old virtual environment if it exists
if [ -d "venv" ]; then
    echo "🗑️  Removing old virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
echo "🐍 Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "✅ Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📦 Installing Firebase Functions dependencies..."
pip install -r requirements.txt

# Verify installation
echo ""
echo "🔍 Verifying installation..."
python -c "import firebase_functions; import firebase_admin; print('✅ All dependencies installed successfully!')"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo ""
echo "To deploy the functions:"
echo "  Development: firebase deploy --only functions --project maypole-flutter-dev"
echo "  Production:  firebase deploy --only functions --project maypole-flutter-ce6c3"
echo ""
echo "To activate the virtual environment manually:"
echo "  source functions/venv/bin/activate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
