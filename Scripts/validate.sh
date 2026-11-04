#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
swift test --enable-code-coverage
bash Scripts/coverage.sh
bash Scripts/build-apps.sh
echo "Package and app validation completed. Live M1 fixture tests require Scripts/test-window-integration.sh; Living Window (M2) remains pending."
