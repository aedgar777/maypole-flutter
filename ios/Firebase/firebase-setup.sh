#!/bin/sh

# Firebase Config Switcher Script
# This script copies the correct GoogleService-Info.plist based on the build configuration

# Get the build configuration (e.g., dev-Debug, prod-Release, etc.)
CONFIGURATION="${CONFIGURATION}"

# Determine which Firebase config to use
if [[ "${CONFIGURATION}" == *"dev"* ]]; then
    echo "Using dev Firebase configuration"
    FIREBASE_SOURCE="${SRCROOT}/Firebase/dev/GoogleService-Info.plist"
elif [[ "${CONFIGURATION}" == *"prod"* ]]; then
    echo "Using prod Firebase configuration"
    FIREBASE_SOURCE="${SRCROOT}/Firebase/prod/GoogleService-Info.plist"
else
    # Default to dev for Debug/Release builds
    echo "Using dev Firebase configuration (default for ${CONFIGURATION})"
    FIREBASE_SOURCE="${SRCROOT}/Firebase/dev/GoogleService-Info.plist"
fi

# Destination
FIREBASE_DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

# Copy the appropriate Firebase config
if [ -f "${FIREBASE_SOURCE}" ]; then
    echo "Copying ${FIREBASE_SOURCE} to ${FIREBASE_DEST}"
    cp "${FIREBASE_SOURCE}" "${FIREBASE_DEST}"
else
    echo "Error: Firebase config file not found at ${FIREBASE_SOURCE}"
    exit 1
fi
