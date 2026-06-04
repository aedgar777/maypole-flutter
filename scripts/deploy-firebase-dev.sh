#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

set -a
source .env
set +a

if [ -z "${GOOGLE_PLACES_SERVER_DEV_API_KEY:-}" ]; then
  echo "Missing GOOGLE_PLACES_SERVER_DEV_API_KEY in .env"
  exit 1
fi

printf '%s' "$GOOGLE_PLACES_SERVER_DEV_API_KEY" | firebase functions:secrets:set GOOGLE_PLACES_API_KEY \
  --project maypole-flutter-dev \
  --data-file - \
  --force

firebase deploy \
  --only firestore:rules,firestore:indexes,storage,functions \
  --project maypole-flutter-dev
