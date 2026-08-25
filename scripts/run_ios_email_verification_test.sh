#!/usr/bin/env bash
#
# End-to-end check of the iOS email registration + verification flow.
#
#   1. Registers a brand-new account and asserts the success dialog appears
#      and routes to home                                        (bug #1)
#   2. Opens the verification mail in Gmail, follows the link, and asserts the
#      "Continue to Maypole" button returns to the NATIVE app    (bug #2)
#
# MUST be run on macOS with Xcode and an attached, unlocked iPhone. Maestro's
# iOS driver cannot run on Linux.
#
# Each run registers a fresh account using a Gmail "+" alias, so there is no
# need to delete the previous test user between runs. The alias still delivers
# to the base inbox.
#
# Environment overrides:
#   GMAIL_BASE   - base Gmail address that receives the mail
#   REG_PASSWORD - password for the throwaway account (random if unset)
#   DEVICE       - Maestro --device id, if more than one is attached
set -uo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ This script must run on macOS — Maestro's iOS driver needs Xcode."
  echo "   Current platform: $(uname -s)"
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ xcodebuild not found. Install Xcode and its command line tools."
  exit 1
fi

if ! command -v maestro >/dev/null 2>&1; then
  echo "❌ maestro not found. Install it: https://maestro.mobile.dev"
  exit 1
fi

GMAIL_BASE="${GMAIL_BASE:-aedgar777@gmail.com}"
STAMP="$(date +%s)"
REG_EMAIL="${GMAIL_BASE%@*}+mp${STAMP}@${GMAIL_BASE#*@}"
REG_USERNAME="mptest${STAMP}"
# Generated, not hardcoded — this account is disposable.
REG_PASSWORD="${REG_PASSWORD:-Mp!$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12)}"

DEVICE_ARG=()
if [[ -n "${DEVICE:-}" ]]; then
  DEVICE_ARG=(--device "$DEVICE")
fi

log() { echo -e "\n=== $* ==="; }

log "Test account for this run"
echo "  email:    $REG_EMAIL"
echo "  username: $REG_USERNAME"
echo "  (password generated for this run only)"

log "Attached iOS devices"
maestro "${DEVICE_ARG[@]}" --version >/dev/null 2>&1
xcrun xctrace list devices 2>/dev/null | sed -n '/^== Devices ==/,/^== /p' | head -10

# ---- Step 1: registration + post-registration feedback ----------------------
log "Step 1/2: register and assert success feedback (bug #1)"
if ! maestro "${DEVICE_ARG[@]}" test .maestro/register_and_assert_feedback.yaml \
  -e REG_EMAIL="$REG_EMAIL" \
  -e REG_PASSWORD="$REG_PASSWORD" \
  -e REG_USERNAME="$REG_USERNAME"; then
  echo ""
  echo "❌ FAIL (bug #1): registration did not produce visible success feedback,"
  echo "   or did not route to the home screen."
  echo "   Test account left in place for inspection: $REG_EMAIL"
  exit 1
fi
echo "✅ Step 1 passed: success dialog shown and routed to home."

# ---- Step 2: verification link returns to the native app --------------------
log "Step 2/2: verify from Gmail and assert return to native app (bug #2)"
if ! maestro "${DEVICE_ARG[@]}" test .maestro/verify_email_from_gmail.yaml \
  -e REG_EMAIL="$REG_EMAIL"; then
  echo ""
  echo "❌ FAIL (bug #2): the verification link did not return to the native app."
  echo "   Most likely the maypole:// handoff in web/auth-action.html did not fire,"
  echo "   or the deployed auth-action.html predates that fix — redeploy web hosting."
  echo "   Test account left in place for inspection: $REG_EMAIL"
  exit 1
fi

log "✅ PASS: registration feedback and email verification deep link both work."
echo "   Test account: $REG_EMAIL"
