#!/bin/bash

# Environment Validation Script for Maypole Flutter App
# Usage: ./scripts/validate-env.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")")
ENV_FILE="$PROJECT_ROOT/.env.local"

echo "🔍 Validating $ENVIRONMENT environment configuration..."

# Check if .env.local exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env.local not found!"
    echo "📋 Please run: cp .env.local.example .env.local"
    exit 1
fi

# Define required variables based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
    REQUIRED_VARS=(
        "FIREBASE_PROD_WEB_API_KEY"
        "FIREBASE_PROD_WEB_APP_ID"
        "FIREBASE_PROD_WEB_MEASUREMENT_ID"
        "FIREBASE_PROD_ANDROID_API_KEY"
        "FIREBASE_PROD_ANDROID_APP_ID"
        "FIREBASE_PROD_IOS_API_KEY"
        "FIREBASE_PROD_IOS_APP_ID"
        "FIREBASE_PROD_WINDOWS_APP_ID"
        "FIREBASE_PROD_WINDOWS_MEASUREMENT_ID"
        "FIREBASE_PROD_MESSAGING_SENDER_ID"
        "FIREBASE_PROD_PROJECT_ID"
        "FIREBASE_PROD_AUTH_DOMAIN"
        "FIREBASE_PROD_STORAGE_BUCKET"
        "IOS_BUNDLE_ID"
    )
else
    REQUIRED_VARS=(
        "FIREBASE_DEV_WEB_API_KEY"
        "FIREBASE_DEV_WEB_APP_ID"
        "FIREBASE_DEV_WEB_MEASUREMENT_ID"
        "FIREBASE_DEV_ANDROID_API_KEY"
        "FIREBASE_DEV_ANDROID_APP_ID"
        "FIREBASE_DEV_IOS_API_KEY"
        "FIREBASE_DEV_IOS_APP_ID"
        "FIREBASE_DEV_MESSAGING_SENDER_ID"
        "FIREBASE_DEV_PROJECT_ID"
        "FIREBASE_DEV_AUTH_DOMAIN"
        "FIREBASE_DEV_STORAGE_BUCKET"
        "IOS_BUNDLE_ID"
    )
fi

# Check each required variable
MISSING_VARS=()
for VAR in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^${VAR}=" "$ENV_FILE" || grep -q "^${VAR}=$" "$ENV_FILE" || grep -q "^${VAR}=your_.*_here" "$ENV_FILE"; then
        MISSING_VARS+=("$VAR")
    fi
done

# Report results
if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo "✅ All required environment variables are set for $ENVIRONMENT"
    
    # Check ENVIRONMENT variable
    if grep -q "^ENVIRONMENT=$ENVIRONMENT$" "$ENV_FILE"; then
        echo "✅ ENVIRONMENT is set to: $ENVIRONMENT"
    else
        echo "⚠️  Warning: ENVIRONMENT in .env.local doesn't match $ENVIRONMENT"
        echo "   Current: $(grep '^ENVIRONMENT=' "$ENV_FILE" || echo 'not set')"
        echo "   Expected: ENVIRONMENT=$ENVIRONMENT"
    fi
    
    echo "🚀 Configuration is ready for $ENVIRONMENT deployment!"
else
    echo "❌ Missing or empty environment variables:"
    for VAR in "${MISSING_VARS[@]}"; do
        echo "   - $VAR"
    done
    echo ""
    echo "🔑 Get these values from Firebase Console:"
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo "   https://console.firebase.google.com/project/maypole-flutter-ce6c3/settings/general"
    else
        echo "   https://console.firebase.google.com/project/maypole-flutter-dev/settings/general"
    fi
    exit 1
fi