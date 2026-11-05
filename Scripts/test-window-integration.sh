#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Opt-in only: mutates Test Lab fixtures, never grants permissions or touches other apps.
if pgrep -x Kinetiq >/dev/null; then
    echo "Stop Kinetiq normally before running independent AETHER native-window tests. No mutation started."
    exit 2
fi
if swift -e 'import ApplicationServices; import Carbon; import Darwin; exit(AXIsProcessTrusted() && !IsSecureEventInputEnabled() ? 0 : 2)'; then
    :
else
    echo "Unlock the desktop, finish secure input and explicitly grant Accessibility to this test host. No fixture mutation started."
    exit 2
fi
if pgrep -x 'AETHER Test Lab' >/dev/null; then
    echo "Quit Test Lab before running this script so fixture identities are unique."
    exit 2
fi
bash Scripts/build-apps.sh
open -n '.build/Xcode/Build/Products/Debug/AETHER Test Lab.app' --args --m1-fixtures
AETHER_RUN_WINDOW_INTEGRATION=1 swift test --enable-code-coverage --filter NativeWindowTests