#!/bin/bash

# Deploy All Firebase Tools to Production (maypole-flutter-ce6c3)
# This script deploys Firestore rules, indexes, storage rules, and functions to production

set -e  # Exit on error

echo "☁️  Deploying Firebase tools to Production..."
echo "════════════════════════════════════════════════════════════"

# Deploy all Firebase tools to production project
firebase deploy \
    --only firestore:rules,firestore:indexes,storage,functions \
    --project maypole-flutter-ce6c3

echo ""
echo "✅ Firebase tools deployed to production!"
echo ""
echo "📊 Production Console:"
echo "   https://console.firebase.google.com/project/maypole-flutter-ce6c3"
