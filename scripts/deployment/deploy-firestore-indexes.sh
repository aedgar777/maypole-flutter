#!/bin/bash

# Deploy Firebase Firestore Indexes
# This script deploys the firestore.indexes.json file to Firebase

set -e

echo "🔥 Deploying Firestore Indexes..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Deploy firestore indexes
firebase deploy --only firestore:indexes

echo "✅ Firestore indexes deployment initiated!"
echo ""
echo "⚠️  Note: Index creation can take several minutes."
echo "   You'll receive an email when the index is ready."
echo ""
echo "Added index for:"
echo "  - images collection (uploaderId + uploadedAt)"
echo "  - Used for rate limiting queries"
