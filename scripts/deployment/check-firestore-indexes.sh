#!/bin/bash

# Script to check Firestore index status
# Opens the Firebase Console to the indexes page

echo "🔍 Checking Firestore indexes status..."
echo ""
echo "Opening Firebase Console..."
echo ""

# Open the indexes page in default browser
open "https://console.firebase.google.com/project/maypole-flutter-dev/firestore/indexes"

echo "✅ Check the 'Status' column in the Indexes tab:"
echo ""
echo "   🟢 Enabled  = Index is ready to use!"
echo "   🟡 Building = Index is still being created (wait a few more minutes)"
echo "   🔴 Error    = Something went wrong"
echo ""
echo "Expected indexes:"
echo "  1. Collection Group 'images': uploaderId (ASC), uploadedAt (DESC)"
echo "  2. Collection 'images': uploadedAt (DESC)"
echo ""
