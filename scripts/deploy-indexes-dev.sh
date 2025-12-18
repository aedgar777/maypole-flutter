#!/bin/bash

# Deploy Firestore indexes to development environment
# Usage: ./scripts/deploy-indexes-dev.sh

set -e

echo "🚀 Deploying Firestore indexes to DEV..."
firebase deploy --only firestore:indexes --project maypole-flutter-dev

echo ""
echo "✅ Deployment complete!"
echo ""
echo "⏳ Note: Indexes may take a few minutes to build."
echo "   Check status at: https://console.firebase.google.com/project/maypole-flutter-dev/firestore/indexes"
