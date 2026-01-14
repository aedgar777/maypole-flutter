#!/bin/bash

# Maypole Flutter Project Setup Script
# For private team members

set -e

echo " Setting up Maypole Flutter project for team development..."
echo ""

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo " Creating .env.local template from example..."
    cp .env.example .env.local
    echo "✅ Created .env.local template"
    echo ""
    echo " TEAM SETUP REQUIRED:"
    echo ""
    echo "You need to get the actual Firebase configuration from your team admin:"
    echo ""
    echo " What your team admin should provide:"
    echo "1.  Pre-configured .env.local file with actual team secrets"
    echo "2.  google-services.json for Android development"
    echo "3.  GoogleService-Info.plist for iOS development (if needed)"
    echo "4.  Firebase project access via your Google account"
    echo ""
    echo " Contact your team admin for:"
    echo "- GitHub repository access"
    echo "- Firebase project permissions"
    echo "- Team secrets and configuration files"
    echo ""
    echo " See the Team Setup Guide: docs/contributors/firebase-setup-guide.md"
else
    echo "✅ .env.local already exists"
    
    # Check if it looks like it has real values (not just template)
    if grep -q "your_.*_api_key_here" .env.local; then
        echo "⚠️  .env.local contains template values"
        echo "   You need the actual team Firebase configuration"
        echo ""
        echo " Contact your team admin to get:"
        echo "- Pre-configured .env.local with actual team secrets"
        echo "- Access to Firebase projects: maypole-flutter-dev and maypole-flutter-ce6c3"
    else
        echo " Firebase team configuration detected"
    fi
fi

# Check if google-services.json exists
if [ ! -f "android/app/google-services.json" ]; then
    echo ""
    echo "⚠️  android/app/google-services.json not found"
    echo "   This file is required for Android development"
    echo ""
    echo " Contact your team admin to get:"
    echo "- The actual google-services.json file for the team's Firebase project"
    echo "- Place it in android/app/google-services.json"
    echo ""
    echo "   You can use android/app/google-services.json.example as a reference"
else
    echo "✅ android/app/google-services.json found"
fi

# Check if GoogleService-Info.plist exists (for iOS)
if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "ℹ️  ios/Runner/GoogleService-Info.plist not found (iOS configuration)"
    echo "   This is optional unless you're developing for iOS"
    echo "   If needed, get it from your team admin and place it in ios/Runner/"
else
    echo "✅ ios/Runner/GoogleService-Info.plist found"
fi

# Install Flutter dependencies
echo ""
echo " Installing Flutter dependencies..."
flutter pub get

echo ""
echo " Setup complete!"
echo ""

# Check if configuration looks ready for team development
if [ -f ".env.local" ] && [ -f "android/app/google-services.json" ]; then
    # Check if .env.local has real values
    if ! grep -q "your_.*_api_key_here" .env.local; then
        echo "✅ Your project appears to be configured for team development!"
        echo ""
        echo " Ready to run against shared development environment:"
        echo "   flutter run"
        echo ""
        echo " Ready to build:"
        echo "   flutter build web"
        echo "   flutter build apk"
        echo ""
        echo "  Development Environment:"
        echo "   - You'll be working against the shared 'maypole-flutter-dev' Firebase project"
        echo "   - Coordinate with your team before making major schema changes"
        echo "   - Use shared test accounts and data for development"
        echo ""
        echo " Note: The app automatically loads .env.local for local development"
        echo "       GitHub Actions will generate .env for CI/CD builds"
    else
        echo " Team configuration needed:"
        echo "   Your .env.local still contains template values"
        echo "   Please get the actual team configuration from your admin"
    fi
else
    echo " Team setup incomplete:"
    echo "   Please get the required files from your team admin:"
    echo "   - .env.local with actual team Firebase configuration"
    echo "   - android/app/google-services.json for Android development"
    echo "   - Firebase project access via your Google account"
fi

echo ""
echo " Documentation:"
echo "    Team Setup Guide: docs/contributors/firebase-setup-guide.md"
echo "    Detailed Setup Instructions: SETUP.md"
echo "    Troubleshooting: Check SETUP.md or ask your team"
echo ""
echo " Team Development:"
echo "   - Development against shared Firebase projects"
echo "   - Coordinate major changes with your team"
echo "   - Production access restricted to senior team members"
echo "   - Deployment handled automatically via GitHub Actions"