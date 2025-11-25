#!/bin/bash

# Script to fix CORS issues for Firebase Storage and deploy Cloud Functions
# Usage: ./scripts/fix-cors-issues.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}

echo "🔧 Fixing CORS issues for $ENVIRONMENT environment..."

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Determine project ID and bucket based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
    PROJECT_ID="maypole-flutter-ce6c3"
    BUCKET="gs://maypole-flutter-ce6c3.firebasestorage.app"
else
    PROJECT_ID="maypole-flutter-dev"
    BUCKET="gs://maypole-flutter-dev.firebasestorage.app"
fi

echo -e "${BLUE}📦 Project: $PROJECT_ID${NC}"
echo -e "${BLUE}🪣 Bucket: $BUCKET${NC}"
echo ""

# Check if gsutil is installed
if ! command -v gsutil &> /dev/null; then
    echo -e "${RED}❌ gsutil is not installed${NC}"
    echo -e "${YELLOW}Please install Google Cloud SDK:${NC}"
    echo "  macOS: brew install google-cloud-sdk"
    echo "  Linux: curl https://sdk.cloud.google.com | bash"
    echo "  Windows: Download from https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed${NC}"
    echo -e "${YELLOW}Please install it with: npm install -g firebase-cli${NC}"
    exit 1
fi

# Set the Google Cloud project
echo -e "${BLUE}🔧 Setting Google Cloud project...${NC}"
gcloud config set project $PROJECT_ID

# Apply CORS configuration to Firebase Storage
echo -e "${BLUE}🌐 Applying CORS configuration to Firebase Storage...${NC}"
if [ -f "cors.json" ]; then
    gsutil cors set cors.json $BUCKET
    echo -e "${GREEN}✅ CORS configuration applied successfully${NC}"
    
    # Verify CORS configuration
    echo -e "${BLUE}🔍 Verifying CORS configuration...${NC}"
    gsutil cors get $BUCKET
else
    echo -e "${RED}❌ cors.json file not found${NC}"
    exit 1
fi

echo ""

# Deploy Cloud Functions
echo -e "${BLUE}☁️  Deploying Cloud Functions...${NC}"
firebase use $PROJECT_ID
firebase deploy --only functions

echo ""
echo -e "${GREEN}✅ All CORS fixes applied successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Rebuild your web app with: ./scripts/build-web-$ENVIRONMENT.sh"
echo "2. Deploy hosting with: firebase deploy --only hosting"
echo "3. Test your app in a fresh browser window or incognito mode"
