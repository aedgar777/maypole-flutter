#!/bin/bash

# Switch to Development Environment
echo "🔄 Switching to Development Environment..."

# Update ..env.local to set dev environment
if [ -f "env.local" ]; then
    # Update the ENVIRONMENT variable in .env.local
    sed -i '' 's/^ENVIRONMENT=.*/ENVIRONMENT=dev/' .env.local
    echo "✅ Updated env.local to use development environment"
else
    echo "❌ env.local file not found. Please create it from .env.local.example"
    exit 1
fi

# Show current Firebase project
echo "🔥 Current Firebase project: $(grep FIREBASE_DEV_PROJECT_ID .env.local | cut -d'=' -f2)"

echo "✨ Development environment is now active!"
echo "   You can now run the app with:"
echo "   • Android Studio: Select 'maypole (dev)' configuration"
echo "   • Terminal: flutter run --dart-define=ENVIRONMENT=dev --flavor dev"