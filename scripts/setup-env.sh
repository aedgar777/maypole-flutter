#!/bin/bash

# Environment Setup Script for Maypole Flutter App
# Usage: ./scripts/setup-env.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")")

echo "🔧 Setting up $ENVIRONMENT environment..."

# Check if .env.local exists
if [ ! -f "$PROJECT_ROOT/.env.local" ]; then
    echo "❌ .env.local not found!"
    echo "📋 Please copy .env.local.example to .env.local and fill in your Firebase credentials:"
    echo "   cp .env.local.example .env.local"
    echo ""
    echo "🔑 Get credentials from Firebase Console:"
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo "   https://console.firebase.google.com/project/maypole-flutter-ce6c3/settings/general"
    else
        echo "   https://console.firebase.google.com/project/maypole-flutter-dev/settings/general"
    fi
    exit 1
fi

# Set environment in .env.local
if grep -q "^ENVIRONMENT=" "$PROJECT_ROOT/.env.local"; then
    # Update existing ENVIRONMENT line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^ENVIRONMENT=.*/ENVIRONMENT=$ENVIRONMENT/" "$PROJECT_ROOT/.env.local"
    else
        sed -i "s/^ENVIRONMENT=.*/ENVIRONMENT=$ENVIRONMENT/" "$PROJECT_ROOT/.env.local"
    fi
else
    # Add ENVIRONMENT line
    echo "ENVIRONMENT=$ENVIRONMENT" >> "$PROJECT_ROOT/.env.local"
fi

echo "✅ Environment set to: $ENVIRONMENT"

# Check for required Firebase config files
echo "🔍 Checking Firebase configuration files..."

GOOGLE_SERVICES="$PROJECT_ROOT/android/app/google-services.json"
if [ ! -f "$GOOGLE_SERVICES" ]; then
    echo "⚠️  Warning: google-services.json not found in android/app/"
    echo "   Download from Firebase Console → Project Settings → Android app"
fi

GOOGLE_SERVICE_INFO="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
if [ ! -f "$GOOGLE_SERVICE_INFO" ]; then
    echo "⚠️  Warning: GoogleService-Info.plist not found in ios/Runner/"
    echo "   Download from Firebase Console → Project Settings → iOS app"
fi

echo "🚀 Setup complete! You can now run:"
echo "   flutter pub get"
echo "   flutter run"