#!/bin/bash

# Deploy Firebase Storage Rules
# This script deploys the storage.rules file to Firebase

set -e

echo "🔥 Deploying Firebase Storage Rules..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Deploy storage rules
firebase deploy --only storage

echo "✅ Storage rules deployed successfully!"
echo ""
echo "Rules are now active for:"
echo "  - ProfilePictures/{userId}/"
echo "  - profile_pictures/{userId}/"
echo "  - maypole_images/{maypoleId}/"
