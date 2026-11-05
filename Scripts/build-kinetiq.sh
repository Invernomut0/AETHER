#!/bin/bash
# Build the user's real, separately licensed Kinetiq checkout. No source is vendored or linked.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
source_root="${1:-$(dirname "$project_root")/Wobbly}"

if [[ ! -d "$source_root" ]]; then
  echo "Kinetiq checkout not found: $source_root. Pass its directory as the first argument." >&2
  exit 2
fi
source_root="$(cd "$source_root" && pwd -P)"
for required in Package.swift LICENSE NOTICE Resources/Info.plist scripts/build-app.sh Sources/Kinetiq/KinetiqApp.swift; do
  if [[ ! -f "$source_root/$required" ]]; then
    echo "Not a complete Kinetiq checkout: missing $required." >&2
    exit 2
  fi
done
identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_root/Resources/Info.plist")
if [[ "$identifier" != "io.github.invernomut0.Kinetiq" ]]; then
  echo "Refusing an unexpected engine bundle identifier: $identifier." >&2
  exit 2
fi
if /usr/bin/pgrep -x Kinetiq >/dev/null; then
  echo "Quit Kinetiq normally from its wave menu before rebuilding. No process was terminated." >&2
  exit 2
fi

echo "Building the original Kinetiq app from $source_root"
echo "License and attribution remain in $source_root/LICENSE and $source_root/NOTICE"
echo "This runs the checkout's build script. Only use source you trust."
# Ad-hoc by default, not release signing. An explicitly supplied development identity is respected.
# Permission grants belong to Kinetiq and may need reapproval after rebuilding; none are edited here.
SIGN_IDENTITY="${SIGN_IDENTITY:--}" bash "$source_root/scripts/build-app.sh"
app="$source_root/build/Kinetiq.app"
/usr/bin/codesign --verify --deep --strict "$app"
echo "Select $app in AETHER → Effects. Accept the experimental warning, then Start / Connect."
echo "No launch, permission request, native-window movement or settings change was performed."