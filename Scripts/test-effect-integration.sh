#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Explicit, destructive ONLY to the exact external Test Lab disposable fixture.
# No permission requests, global event taps, app termination or user-document writes.
if pgrep -x Kinetiq >/dev/null; then
    echo "Stop Kinetiq normally before running independent AETHER fixture effects. No action started."
    exit 2
fi
if swift -e 'import CoreGraphics; import ApplicationServices; import Carbon; import Darwin; exit(AXIsProcessTrusted() && CGPreflightScreenCaptureAccess() && !IsSecureEventInputEnabled() ? 0 : 2)'; then
    :
else
    echo "Grant AX/Recording explicitly, unlock the desktop and finish secure input. No effect or close requested."
    exit 2
fi
if pgrep -x 'AETHER Test Lab' >/dev/null; then
    echo "Quit Test Lab first: a fresh, unique AETHER Effect Disposable fixture is required."
    exit 2
fi
bash Scripts/build-apps.sh
open -n '.build/Xcode/Build/Products/Debug/AETHER Test Lab.app' --args --m1-fixtures
AETHER_RUN_EFFECT_INTEGRATION=1 swift test --enable-code-coverage --filter WindowEffectIntegrationTests