# M0 Local Validation — 2026-11-04

## Environment and scope
- Apple Silicon Mac; Xcode 27.2 (27B52), Swift 6.4.2, Metal Toolchain 32023.922.
- Compile/deployment target: macOS 14.0. Runtime compatibility with macOS 14 has not been certified on this machine.
- Version 1.0.2, build 3 (M0 introduced in 1.0.1). This validates bootstrap, not the Living Window gate or the full product.

## Initial failures, resolved
- Missing official Metal Toolchain, installed with `xcodebuild -downloadComponent MetalToolchain`.
- Missing comma in the display snapshot construction.
- Missing public initializers for cross-module physics state, effect descriptors and layout nodes.
- Swift 6 access to an imported mutable AX option constant. The public option key was verified against the installed SDK; no private symbol or weakened concurrency setting is used.
- SwiftUI `@main` in files named `main.swift`, resolved with the explicit app compiler flag `-parse-as-library`.
- Unhandled module README files, now excluded from package targets.

## Verified results
- `swift build`: passed.
- `swift test --enable-code-coverage`: passed, 6 original XCTest tests plus 13 Swift Testing tests (19 tests / 24 parameter-expanded cases), no failures.
- `bash Scripts/coverage.sh`: aggregated all test executables. Coordinator line coverage: 97.62%; JSON configuration repository: 89.29%. Aggregate covered library files: 52.80%. Capture/rendering/UI are not covered by these unit tests.
- Debug builds of `AETHERApp` and `AETHERTestLab` with local ad-hoc signing: passed.
- Both app processes launched. The application created its real Application Support configuration with schema 1.
- Quick Look reset/cache refresh and Finder reload performed locally.
- Full workflow: `bash Scripts/validate.sh` (logs under the ignored `.build/` directory).

## Limitations and next gate
- Visual UI inspection and explicit permission interaction remain owner review items. Process launch and configuration creation are not UI automation.
- No permission was granted automatically and no window pixels were captured for this validation.
- CoreSimulator mismatch and generated Metal-bundle node warnings from Xcode are non-blocking for these macOS builds.
- Ad-hoc signing is development-only; stable distribution signing and notarization remain M9 work.
- CI is configured; its remote status is independent of the local test results. The owner-provided origin is `https://github.com/Invernomut0/AETHER.git` on `main`.
- M1 must replace the unsafe first-AX-window controller before exposing native control, then verify multiple real Test Lab windows with explicit Accessibility access.
- M2 must implement ScreenCaptureKit output and reliable overlay cleanup before any visual effect is considered delivered.