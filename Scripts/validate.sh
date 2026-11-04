#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
swift test --enable-code-coverage
bash Scripts/coverage.sh
bash Scripts/build-apps.sh
echo "Package and app validation completed. Opt-in gates: Scripts/test-window-integration.sh (AX), Scripts/test-capture-integration.sh (AX + Recording). M2 live gate remains pending."
