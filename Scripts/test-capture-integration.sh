#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Explicit opt-in only: capture Test Lab, never request or alter permissions.
if swift -e 'import CoreGraphics; import ApplicationServices; import Carbon; import Darwin; exit(AXIsProcessTrusted() && CGPreflightScreenCaptureAccess() && !IsSecureEventInputEnabled() ? 0 : 2)'; then
    :
else
    echo "Unlock the desktop, finish secure input and explicitly grant Accessibility and Screen Recording to this test host. No capture started."
    exit 2
fi
if pgrep -x 'AETHER Test Lab' >/dev/null; then
    echo "Quit Test Lab before running this script so fixture identities are unique."
    exit 2
fi
bash Scripts/build-apps.sh
open -n '.build/Xcode/Build/Products/Debug/AETHER Test Lab.app' --args --m1-fixtures
AETHER_RUN_CAPTURE_INTEGRATION=1 swift test --filter CapturePipelineTests