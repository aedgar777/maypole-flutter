#!/bin/bash

# Script to enable beta testing for a user
# Usage: ./scripts/enable-beta-tester.sh <user_email>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <user_email>"
    echo "Example: $0 user@example.com"
    exit 1
fi

USER_EMAIL="$1"
PROJECT_ID="maypole-flutter-ce6c3"

echo "🔍 Looking up user: $USER_EMAIL"

# Use Firebase CLI to find user and set custom claim
firebase auth:export users.json --project "$PROJECT_ID" 2>/dev/null || true

# Check if user exists
USER_UID=$(firebase auth:export --format=json --project "$PROJECT_ID" 2>/dev/null | grep -A 5 "\"email\": \"$USER_EMAIL\"" | grep "uid" | cut -d'"' -f4 || echo "")

if [ -z "$USER_UID" ]; then
    echo "❌ User not found: $USER_EMAIL"
    echo "Make sure the user has signed up first."
    exit 1
fi

echo "✅ Found user UID: $USER_UID"
echo ""
echo "To enable beta access, run this Firestore command:"
echo ""
echo "firebase firestore:update users/$USER_UID --data '{\"betaTester\": true}' --project $PROJECT_ID"
echo ""
echo "Or manually in Firebase Console:"
echo "1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "2. Navigate to: users/$USER_UID"
echo "3. Add field: betaTester = true (boolean)"
echo ""
echo "To revoke beta access, set betaTester to false or delete the field."
