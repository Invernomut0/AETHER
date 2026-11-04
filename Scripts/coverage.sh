#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# SwiftPM/Xcode may export AETHER.json for only the last test binary.
# Aggregate all macOS XCTest executables against the merged profile instead.
bin_path="$(swift build --show-bin-path)"
profile="$bin_path/codecov/default.profdata"
if [[ ! -f "$profile" ]]; then
  echo "Run swift test --enable-code-coverage before this report." >&2
  exit 1
fi

primary=""
coverage_command=(xcrun llvm-cov report)
while IFS= read -r -d '' binary; do
  if [[ -z "$primary" ]]; then
    primary="$binary"
    coverage_command+=("$binary")
  else
    coverage_command+=(-object "$binary")
  fi
done < <(find "$bin_path" -type f -path '*.xctest/Contents/MacOS/*' -print0)

if [[ -z "$primary" ]]; then
  echo "No macOS test binaries found in $bin_path" >&2
  exit 1
fi

"${coverage_command[@]}" \
  -instr-profile "$profile" -ignore-filename-regex='Tests/|\.build/'