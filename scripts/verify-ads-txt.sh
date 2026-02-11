#!/bin/bash

# Verify ads.txt accessibility and configuration
# This script calls the Cloud Function to check if ads.txt is properly configured

set -e

DOMAIN="${1:-https://maypole.app}"
VERIFICATION_URL="https://us-central1-maypole-flutter-ce6c3.cloudfunctions.net/verifyAdsTxt"

echo "🔍 Verifying ads.txt configuration for $DOMAIN..."
echo ""

# Call the verification endpoint
RESPONSE=$(curl -s "${VERIFICATION_URL}?domain=${DOMAIN}")

# Parse the response
ACCESSIBLE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['accessible'])")
STATUS=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'N/A'))")

echo "📊 Verification Results:"
echo "─────────────────────────────────────────────"

if [ "$ACCESSIBLE" == "True" ]; then
    echo "✅ Status: ACCESSIBLE"
    echo "✅ HTTP Status: $STATUS"
    
    # Show detailed checks
    echo ""
    echo "Detailed Checks:"
    echo "$RESPONSE" | python3 -m json.tool | grep -A 6 "checks"
    
    echo ""
    echo "✅ Your ads.txt file is properly configured and accessible!"
    exit 0
else
    echo "❌ Status: NOT ACCESSIBLE"
    echo "❌ HTTP Status: $STATUS"
    
    # Show error details
    ERROR=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('error', 'Unknown error'))")
    echo ""
    echo "Error: $ERROR"
    
    echo ""
    echo "⚠️  Warning: Your ads.txt file is not accessible!"
    echo ""
    echo "📋 Troubleshooting Steps:"
    echo "1. Run the deployment script to ensure ads.txt is copied:"
    echo "   ./scripts/deployment/prod-deploy-web.sh"
    echo ""
    echo "2. Verify the file exists in build/web/:"
    echo "   ls -la build/web/ads.txt"
    echo ""
    echo "3. Use the backup Cloud Function URL:"
    echo "   https://us-central1-maypole-flutter-ce6c3.cloudfunctions.net/serveAdsTxt"
    echo ""
    exit 1
fi
