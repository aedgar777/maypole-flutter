#!/bin/bash

# Simple fix for Firebase 2nd Gen Functions permissions
# Addresses the specific errors from your deployment

PROJECT_ID="maypole-flutter-ce6c3"

echo "🔧 Quick Fix for Firebase Functions Permissions"
echo "================================================"
echo ""

# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
echo "Project: $PROJECT_ID (Number: $PROJECT_NUMBER)"
echo ""

# The key service accounts that need permissions
EVENTARC_SA="service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com"

echo "Granting permissions to Eventarc Service Agent..."
echo ""

# Fix for "Permission denied while using the Eventarc Service Agent"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${EVENTARC_SA}" \
    --role="roles/eventarc.serviceAgent" \
    --no-user-output-enabled

# Fix for Storage bucket permissions
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${EVENTARC_SA}" \
    --role="roles/storage.admin" \
    --no-user-output-enabled

echo "✅ Permissions granted!"
echo ""
echo "⏱️  Wait 2-3 minutes, then retry:"
echo "   firebase deploy --only functions --project $PROJECT_ID"
