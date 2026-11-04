#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
swift test --enable-code-coverage
bash Scripts/coverage.sh
bash Scripts/build-apps.sh
echo "Package and app validation completed. Run opt-in gates separately: Scripts/test-window-integration.sh (AX), Scripts/test-capture-integration.sh (AX + Recording). Default validation does not certify live gates."
