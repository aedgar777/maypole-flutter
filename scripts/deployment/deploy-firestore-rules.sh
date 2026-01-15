#!/bin/bash

# Deploy Firebase Firestore Rules
# This script deploys the firestore.rules file to Firebase

set -e

echo "🔥 Deploying Firebase Firestore Rules..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Deploy firestore rules
firebase deploy --only firestore:rules

echo "✅ Firestore rules deployed successfully!"
echo ""
echo "Updated rules for:"
echo "  - maypoles/{maypoleId}/images/{imageId}"
echo "  - Image uploads now allow 'id' field in documents"
