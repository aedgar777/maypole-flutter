#!/bin/bash

# Deploy Firestore and Storage rules to production environment
# Usage: ./scripts/deploy-rules-prod.sh

set -e

echo "⚠️  WARNING: You are about to deploy to PRODUCTION!"
echo ""
read -p "Are you sure you want to continue? (yes/no) " -n 3 -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🚀 Deploying Firestore and Storage rules to PROD..."
firebase deploy --only firestore:rules,storage --project maypole-prod

echo ""
echo "✅ Deployment complete!"
echo "   Rules are now active in the production environment."
