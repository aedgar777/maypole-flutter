#!/bin/bash

# Deploy Firestore indexes to production environment
# Usage: ./scripts/deploy-indexes-prod.sh

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
echo "🚀 Deploying Firestore indexes to PROD..."
firebase deploy --only firestore:indexes --project maypole-prod

echo ""
echo "✅ Deployment complete!"
echo ""
echo "⏳ Note: Indexes may take a few minutes to build."
echo "   Check status at: https://console.firebase.google.com/project/maypole-prod/firestore/indexes"
