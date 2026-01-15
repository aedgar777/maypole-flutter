#!/bin/bash

# Fix Firebase Functions Permissions for 2nd Gen Functions
# This script grants the necessary IAM roles to Firebase service agents

set -e  # Exit on error

PROJECT_ID="maypole-flutter-ce6c3"

echo "🔧 Fixing Firebase Functions Permissions for Project: $PROJECT_ID"
echo "================================================================"
echo ""

# Check if user is logged in to gcloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
    echo "⚠️  Not logged in to gcloud. Running gcloud auth login..."
    gcloud auth login
fi

# Set the project
echo "📋 Setting gcloud project to $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"
echo ""

# Get project number
echo "🔍 Fetching project number..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
echo "   Project Number: $PROJECT_NUMBER"
echo ""

# 1. Grant Eventarc Service Agent role
echo "🔐 Granting Eventarc Service Agent role..."
EVENTARC_SA="service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${EVENTARC_SA}" \
    --role="roles/eventarc.serviceAgent" \
    --condition=None
echo "   ✅ Granted roles/eventarc.serviceAgent to $EVENTARC_SA"
echo ""

# 2. Grant Eventarc Event Receiver role to default compute service account
echo "🔐 Granting Eventarc Event Receiver role to compute service account..."
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${COMPUTE_SA}" \
    --role="roles/eventarc.eventReceiver" \
    --condition=None
echo "   ✅ Granted roles/eventarc.eventReceiver to $COMPUTE_SA"
echo ""

# 3. Grant Pub/Sub Publisher role for Eventarc
echo "🔐 Granting Pub/Sub Publisher role to Eventarc service account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${EVENTARC_SA}" \
    --role="roles/pubsub.publisher" \
    --condition=None
echo "   ✅ Granted roles/pubsub.publisher to $EVENTARC_SA"
echo ""

# 4. Grant Storage Object Admin role to default service account for storage triggers
echo "🔐 Granting Storage Object Admin role..."
STORAGE_BUCKET="${PROJECT_ID}.firebasestorage.app"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${EVENTARC_SA}" \
    --role="roles/storage.objectAdmin" \
    --condition=None
echo "   ✅ Granted roles/storage.objectAdmin to $EVENTARC_SA"
echo ""

# 5. Grant Storage Admin role to Eventarc for bucket validation
echo "🔐 Granting Storage Admin role for bucket validation..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${EVENTARC_SA}" \
    --role="roles/storage.admin" \
    --condition=None
echo "   ✅ Granted roles/storage.admin to $EVENTARC_SA"
echo ""

# 6. Grant roles to App Engine default service account (used by Cloud Functions)
echo "🔐 Granting roles to App Engine default service account..."
APPENGINE_SA="${PROJECT_ID}@appspot.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${APPENGINE_SA}" \
    --role="roles/firebase.sdkAdminServiceAgent" \
    --condition=None
echo "   ✅ Granted roles/firebase.sdkAdminServiceAgent to $APPENGINE_SA"
echo ""

# 7. Grant Cloud Run Invoker role to allow functions to be invoked
echo "🔐 Granting Cloud Run Invoker role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${COMPUTE_SA}" \
    --role="roles/run.invoker" \
    --condition=None
echo "   ✅ Granted roles/run.invoker to $COMPUTE_SA"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ All Permissions Granted Successfully!                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "⏱️  Please wait 2-3 minutes for IAM changes to propagate"
echo ""
echo "Then retry your deployment with:"
echo "   firebase deploy --only functions --project $PROJECT_ID"
echo ""
