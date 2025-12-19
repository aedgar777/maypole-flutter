#!/bin/bash

# Get current branch name
BRANCH=$(git branch --show-current)

# Determine which Firebase project to use based on branch
if [[ "$BRANCH" == "main" ]] || [[ "$BRANCH" == "master" ]]; then
    PROJECT="prod"
    echo "📦 Deploying to PRODUCTION (maypole-flutter)..."
else
    PROJECT="dev"
    echo "🔧 Deploying to DEV (maypole-flutter-dev)..."
fi

# Switch to the appropriate project and deploy
firebase use $PROJECT
firebase deploy --only firestore:rules

echo "✅ Firestore rules deployed to $PROJECT successfully!"
