#!/bin/bash
set -euo pipefail
# Template only. Configure APP_PATH, KEYCHAIN_PROFILE and signing identity securely.
: "${APP_PATH:?Set APP_PATH to the signed .app}"
: "${KEYCHAIN_PROFILE:?Set KEYCHAIN_PROFILE to a notarytool keychain profile}"
xcrun notarytool submit "$APP_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
