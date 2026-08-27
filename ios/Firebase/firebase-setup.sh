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

# ---- Google Sign-In URL scheme ---------------------------------------------
#
# Google Sign-In returns to the app through a custom URL scheme that is unique
# per OAuth client, so it differs between the dev and prod Firebase projects.
# Hardcoding either one in the checked-in Info.plist would break the other
# environment, so derive it from whichever GoogleService-Info.plist was just
# selected above and patch the *built* Info.plist.
#
# Also mirror CLIENT_ID into GIDClientID: the Google Sign-In SDK looks there
# when no client ID is supplied programmatically, which keeps the native side
# working even if the Dart-level configuration is missing.
PLIST_BUDDY="/usr/libexec/PlistBuddy"
APP_INFO_PLIST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Info.plist"

REVERSED_CLIENT_ID=$("${PLIST_BUDDY}" -c "Print :REVERSED_CLIENT_ID" "${FIREBASE_SOURCE}" 2>/dev/null)
GOOGLE_CLIENT_ID=$("${PLIST_BUDDY}" -c "Print :CLIENT_ID" "${FIREBASE_SOURCE}" 2>/dev/null)

if [ -z "${REVERSED_CLIENT_ID}" ]; then
    # Not fatal: a project with Google Sign-In disabled has no such key, and
    # every other part of the app still builds and runs. Warn loudly, because
    # the symptom otherwise is a sign-in flow that opens and never comes back.
    echo "warning: REVERSED_CLIENT_ID missing from ${FIREBASE_SOURCE}. Google Sign-In will not be able to return to the app. Enable Google as a sign-in provider in the Firebase console and re-download GoogleService-Info.plist."
elif [ ! -f "${APP_INFO_PLIST}" ]; then
    echo "warning: ${APP_INFO_PLIST} not found; skipping Google Sign-In URL scheme setup."
else
    # Xcode does not always regenerate Info.plist on an incremental build, so
    # this can run against a plist we already patched. Appending again would
    # stack duplicate URL types build after build.
    EXISTING_URL_TYPES=$("${PLIST_BUDDY}" -c "Print :CFBundleURLTypes" "${APP_INFO_PLIST}" 2>/dev/null)

    if echo "${EXISTING_URL_TYPES}" | grep -q "${REVERSED_CLIENT_ID}"; then
        echo "Google Sign-In URL scheme already present; leaving it alone"
    else
        echo "Adding Google Sign-In URL scheme (${REVERSED_CLIENT_ID})"

        # Append a URL type rather than replacing the array — the app's own
        # "maypole" scheme lives there too and deep links depend on it.
        #
        # An absent array and an empty one are different failures: the first
        # needs creating before anything can be added to it, and PlistBuddy
        # reports it by failing the Print above rather than by printing
        # nothing, so test for the array itself rather than for its contents.
        if [ -z "${EXISTING_URL_TYPES}" ]; then
            URL_TYPE_INDEX=0
            "${PLIST_BUDDY}" -c "Add :CFBundleURLTypes array" "${APP_INFO_PLIST}"
        else
            # One line reading "Dict {" per existing entry; the count is the
            # index the next entry lands at.
            URL_TYPE_INDEX=$(echo "${EXISTING_URL_TYPES}" | grep -c "Dict {")
        fi

        "${PLIST_BUDDY}" -c "Add :CFBundleURLTypes:${URL_TYPE_INDEX} dict" "${APP_INFO_PLIST}"
        "${PLIST_BUDDY}" -c "Add :CFBundleURLTypes:${URL_TYPE_INDEX}:CFBundleTypeRole string Editor" "${APP_INFO_PLIST}"
        "${PLIST_BUDDY}" -c "Add :CFBundleURLTypes:${URL_TYPE_INDEX}:CFBundleURLName string GoogleSignIn" "${APP_INFO_PLIST}"
        "${PLIST_BUDDY}" -c "Add :CFBundleURLTypes:${URL_TYPE_INDEX}:CFBundleURLSchemes array" "${APP_INFO_PLIST}"
        "${PLIST_BUDDY}" -c "Add :CFBundleURLTypes:${URL_TYPE_INDEX}:CFBundleURLSchemes:0 string ${REVERSED_CLIENT_ID}" "${APP_INFO_PLIST}"
    fi

    if [ -n "${GOOGLE_CLIENT_ID}" ]; then
        # Set, falling back to Add, so a rebuild over an existing product works.
        "${PLIST_BUDDY}" -c "Set :GIDClientID ${GOOGLE_CLIENT_ID}" "${APP_INFO_PLIST}" 2>/dev/null \
            || "${PLIST_BUDDY}" -c "Add :GIDClientID string ${GOOGLE_CLIENT_ID}" "${APP_INFO_PLIST}"
    fi
fi
