#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
swift test --enable-code-coverage
bash Scripts/coverage.sh
bash Scripts/build-apps.sh
echo "M0 validation completed. M1 and Living Window integration gates still require explicit user permissions and Test Lab verification."
