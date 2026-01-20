#!/bin/sh

# Firebase Config Switcher Script
# This script copies the correct GoogleService-Info.plist based on the build configuration

# Get the build configuration (e.g., dev-Debug, prod-Release, etc.)
CONFIGURATION="${CONFIGURATION}"

# Check DART_DEFINES for ENVIRONMENT setting (passed via --dart-define)
# DART_DEFINES is a comma-separated list of base64-encoded values
ENVIRONMENT=""
if [ -n "$DART_DEFINES" ]; then
    # Decode DART_DEFINES to find ENVIRONMENT setting
    # Each define is base64 encoded, decode and check for ENVIRONMENT=
    for define in $(echo "$DART_DEFINES" | tr ',' '\n'); do
        decoded=$(echo "$define" | base64 -d 2>/dev/null || echo "$define")
        if [[ "$decoded" == ENVIRONMENT=* ]]; then
            ENVIRONMENT="${decoded#ENVIRONMENT=}"
            echo "Found ENVIRONMENT in DART_DEFINES: $ENVIRONMENT"
            break
        fi
    done
fi

# Determine which Firebase config to use
# Priority: DART_DEFINES > CONFIGURATION name
if [[ "$ENVIRONMENT" == "production" ]] || [[ "$ENVIRONMENT" == "prod" ]]; then
    echo "Using prod Firebase configuration (from DART_DEFINES)"
    FIREBASE_SOURCE="${SRCROOT}/Firebase/prod/GoogleService-Info.plist"
elif [[ "$ENVIRONMENT" == "dev" ]] || [[ "$ENVIRONMENT" == "development" ]]; then
    echo "Using dev Firebase configuration (from DART_DEFINES)"
    FIREBASE_SOURCE="${SRCROOT}/Firebase/dev/GoogleService-Info.plist"
elif [[ "${CONFIGURATION}" == *"dev"* ]]; then
    echo "Using dev Firebase configuration (from CONFIGURATION: ${CONFIGURATION})"
    FIREBASE_SOURCE="${SRCROOT}/Firebase/dev/GoogleService-Info.plist"
elif [[ "${CONFIGURATION}" == *"prod"* ]]; then
    echo "Using prod Firebase configuration (from CONFIGURATION: ${CONFIGURATION})"
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
