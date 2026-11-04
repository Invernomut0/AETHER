#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! xcrun metal --version >/dev/null 2>&1; then
  echo "Metal Toolchain is required. Install it with: xcodebuild -downloadComponent MetalToolchain" >&2
  exit 1
fi

# Local development only: ad-hoc signing is not release signing or notarization.
for scheme in AETHERApp AETHERTestLab; do
  xcodebuild -quiet -project AETHER.xcodeproj -scheme "$scheme" \
    -configuration Debug -destination 'platform=macOS' \
    -derivedDataPath .build/Xcode build CODE_SIGN_IDENTITY=-
done

echo "Built .build/Xcode/Build/Products/Debug/AETHER.app"
echo "Built .build/Xcode/Build/Products/Debug/AETHER Test Lab.app"