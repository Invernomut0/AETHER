# Build and Release

## Local development
Full Xcode is required for application and Metal compilation. If `xcrun metal --version` reports a missing Metal Toolchain, install the official component using `xcodebuild -downloadComponent MetalToolchain`. No administrator credential is collected by AETHER.

Run `bash Scripts/validate.sh` to build the package, run coverage-enabled tests and build both macOS bundles. Run `bash Scripts/build-apps.sh` to rebuild only the applications. These scripts use local ad-hoc signing, not distribution signing.

Outputs:
- `.build/Xcode/Build/Products/Debug/AETHER.app`
- `.build/Xcode/Build/Products/Debug/AETHER Test Lab.app`

Shared `AETHERApp` and `AETHERTestLab` schemes are committed. `Package.swift` contains libraries and tests, not app executable targets. Open the committed `AETHER.xcodeproj` for running apps. The project and `project.yml` both specify version 1.0.5 (build 6), Swift 6 and macOS 14. `-parse-as-library` allows the SwiftUI `@main` declarations in files named `main.swift`.

M1 live control tests require a local interactive desktop and explicit Accessibility consent. Quit Test Lab and run `bash Scripts/test-window-integration.sh`; see `TESTING.md`. CI intentionally does not auto-grant permissions or run fixture mutations.

M2 capture/overlay gate validation requires explicit Screen Recording consent on the test host in addition to Accessibility. Default validation is allowed to skip consent-dependent live capture tests; those skips are not gate acceptance.

Known local tool warnings: Xcode 27.2 can report an out-of-date iOS CoreSimulator and a missing creator for the generated Metal resource bundle's `Contents/MacOS` node. These did not prevent native macOS builds. Do not interpret simulator warnings as evidence that iOS support exists.

```bash
swift --version
swift package resolve
swift build
swift test
```

Open `Package.swift` in Xcode. If using XcodeGen:
```bash
brew install xcodegen
xcodegen generate
open AETHER.xcodeproj
```

## Signing
Use a Developer ID Application identity for direct distribution. Configure team and signing in Xcode. Do not commit certificates, private keys, provisioning profiles or notarization credentials.

## Notarization
The `Scripts/notarize.sh` file is a template. Configure credentials in Keychain or environment securely. Never put secrets in source control.

## Release checklist
- Build on minimum supported macOS SDK target.
- Run all tests.
- Run Test Lab integration suite.
- Run consented M2 capture/overlay integration tests on a host with `AX=true` and `Recording=true`.
- Run multi-display and sleep/wake tests.
- Verify permissions and revocation behavior.
- Verify no orphan overlays.
- Inspect hardened runtime and entitlements.
- Sign, notarize and staple.
- Produce changelog and known limitations.

## Current release gate status (2026-11-04)
- M0 and M1 are locally accepted.
- Version 1.0.5 records a passed local M2 capture/overlay proof, not full platform certification or Living Window Gate 0 acceptance.
- Latest consented host state was `AX=true`, `Recording=true`, secure input off. Three consecutive capture suites passed (12 functions executed, two denial functions inapplicable); separate native regression passed 14/14. See `M2_VALIDATION.md` for the initial focus failure and remaining checks.
- Do not advance to M3 until the M2 capture/overlay exit gate passes. M3 supplies animation for the broader Living Window Gate 0; neither milestone implies release readiness.
