#!/bin/bash

# Switch to Production Environment
echo "🔄 Switching to Production Environment..."

# Update .env.local to set prod environment
if [ -f "env.local" ]; then
    # Update the ENVIRONMENT variable in env.local
    sed -i '' 's/^ENVIRONMENT=.*/ENVIRONMENT=production/' env.local
    echo "✅ Updated env.local to use production environment"
else
    echo "❌ env.local file not found. Please create it from .env.local.example"
    exit 1
fi

# Show current Firebase project
echo "🔥 Current Firebase project: $(grep FIREBASE_PROD_PROJECT_ID env.local | cut -d'=' -f2)"

echo "✨ Production environment is now active!"
echo "   You can now run the app with:"
echo "   • Android Studio: Select 'maypole (production)' configuration"
echo "   • Terminal: flutter run --dart-define=ENVIRONMENT=production --flavor prod"