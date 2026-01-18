#!/bin/bash
# Verbose wrapper for xcode_backend.sh to debug CI hangs
# This wraps Flutter's build script to add logging

set -e

echo "🔍 [WRAPPER] Verbose Xcode Backend Wrapper Started"
echo "🔍 [WRAPPER] Time: $(date)"
echo "🔍 [WRAPPER] Script: $0"
echo "🔍 [WRAPPER] Args: $@"
echo "🔍 [WRAPPER] PWD: $(pwd)"
echo "🔍 [WRAPPER] FLUTTER_ROOT: ${FLUTTER_ROOT}"
echo "🔍 [WRAPPER] ACTION: ${ACTION}"
echo "🔍 [WRAPPER] CONFIGURATION: ${CONFIGURATION}"

# Log environment variables
echo "🔍 [WRAPPER] Key Environment Variables:"
env | grep -E "(FLUTTER|XCODE|BUILD|SOURCE|BUILT)" | sort

# Start a background heartbeat
(
    while true; do
        sleep 10
        echo "💓 [HEARTBEAT] xcode_backend.sh still running at $(date +%H:%M:%S)"
    done
) &
HEARTBEAT_PID=$!

echo "🔍 [WRAPPER] Starting actual xcode_backend.sh..."

# Run the actual Flutter script with output
"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@" 2>&1 | while IFS= read -r line; do
    echo "[xcode_backend.sh] $line"
done

EXIT_CODE=${PIPESTATUS[0]}

# Kill heartbeat
kill $HEARTBEAT_PID 2>/dev/null || true

echo "🔍 [WRAPPER] xcode_backend.sh completed with exit code: $EXIT_CODE"
echo "🔍 [WRAPPER] Time: $(date)"

exit $EXIT_CODE
