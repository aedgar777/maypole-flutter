#!/bin/bash

# This script helps verify you have all the GitHub secrets set up correctly
# Run this locally to see what secrets are defined in your .env file

echo "🔍 Verifying GitHub Secrets Configuration"
echo "=========================================="
echo ""
echo "This script checks your local .env file and tells you which"
echo "secrets you need to add to GitHub Actions."
echo ""

if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create a .env file first."
    exit 1
fi

# Load .env
set -a
source .env
set +a

echo "📋 Required GitHub Secrets for DEVELOPMENT:"
echo "-------------------------------------------"

secrets_dev=(
    "FIREBASE_DEV_WEB_API_KEY"
    "FIREBASE_DEV_WEB_APP_ID"
    "FIREBASE_DEV_WEB_MEASUREMENT_ID"
    "FIREBASE_DEV_MESSAGING_SENDER_ID"
    "FIREBASE_DEV_PROJECT_ID"
    "FIREBASE_DEV_AUTH_DOMAIN"
    "FIREBASE_DEV_STORAGE_BUCKET"
)

for secret in "${secrets_dev[@]}"; do
    value="${!secret}"
    if [ -z "$value" ]; then
        echo "❌ $secret - MISSING in .env"
    else
        # Show first 10 chars to verify

        echo "✅ $secret - Present"
    fi
done

echo ""
echo "📋 Required GitHub Secrets for PRODUCTION:"
echo "------------------------------------------"

secrets_prod=(
    "FIREBASE_PROD_WEB_API_KEY"
    "FIREBASE_PROD_WEB_APP_ID"
    "FIREBASE_PROD_WEB_MEASUREMENT_ID"
    "FIREBASE_PROD_MESSAGING_SENDER_ID"
    "FIREBASE_PROD_PROJECT_ID"
    "FIREBASE_PROD_AUTH_DOMAIN"
    "FIREBASE_PROD_STORAGE_BUCKET"
)

for secret in "${secrets_prod[@]}"; do
    value="${!secret}"
    if [ -z "$value" ]; then
        echo "❌ $secret - MISSING in .env"
    else
        echo "✅ $secret - Present "
    fi
done

echo ""
echo "📋 Service Account Secrets:"
echo "--------------------------"
echo "⚠️  MAYPOLE_FIREBASE_SERVICE_ACCOUNT_DEV - Check GitHub (JSON key)"
echo "⚠️  MAYPOLE_FIREBASE_SERVICE_ACCOUNT - Check GitHub (JSON key)"

echo ""
echo "=========================================="
echo "Next Steps:"
echo "1. Go to: https://github.com/YOUR-USERNAME/YOUR-REPO/settings/secrets/actions"
echo "2. Add each secret listed above"
echo "3. Use the values from your .env file"
echo "4. Generate and add Firebase service account JSON keys"
echo ""
echo "See GITHUB_SECRETS_CHECKLIST.md for detailed instructions."
