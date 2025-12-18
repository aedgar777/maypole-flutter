#!/bin/bash

# Deploy Firestore and Storage rules to development environment
# Usage: ./scripts/deploy-rules-dev.sh

set -e

echo "🚀 Deploying Firestore and Storage rules to DEV..."
firebase deploy --only firestore:rules,storage --project maypole-dev

echo ""
echo "✅ Deployment complete!"
echo "   Rules are now active in the development environment."
