# Build and Release

## Local development
Full Xcode is required for application and Metal compilation. If `xcrun metal --version` reports a missing Metal Toolchain, install the official component using `xcodebuild -downloadComponent MetalToolchain`. No administrator credential is collected by AETHER.

Run `bash Scripts/validate.sh` to build the package, run coverage-enabled tests and build both macOS bundles. Run `bash Scripts/build-apps.sh` to rebuild only the applications. These scripts use local ad-hoc signing, not distribution signing.

Outputs:
- `.build/Xcode/Build/Products/Debug/AETHER.app`
- `.build/Xcode/Build/Products/Debug/AETHER Test Lab.app`

Shared `AETHERApp`/`AETHERTestLab` schemes are committed; Package.swift contains libraries/tests, not app executables. Open `AETHER.xcodeproj` to run apps. Final validation passed AETHER Swift 6 build/default coverage tests/both Xcode apps, and **both actual built Info.plists are 1.0.8/build 9**. Exact local bundles subsequently finished launch and Quick Look/Finder refresh completed, as recorded below. macOS 14 is a deployment target, not runtime certification. `-parse-as-library` permits SwiftUI `@main` in main.swift.

M1 live control tests require a local interactive desktop and explicit Accessibility consent. Quit Test Lab and run `bash Scripts/test-window-integration.sh`; see `TESTING.md`. CI intentionally does not auto-grant permissions or run fixture mutations.

M2 capture/overlay gate validation requires explicit Screen Recording consent on the test host in addition to Accessibility. Default validation is allowed to skip consent-dependent live capture tests; those skips are not gate acceptance.

The new bounded manual M3/M4 slice has a separate real-fixture helper, `bash Scripts/test-effect-integration.sh`, enabling `AETHER_RUN_EFFECT_INTEGRATION=1`. Native-close regression stays under the existing `AETHER_RUN_WINDOW_INTEGRATION=1` gate. Quit Test Lab before each helper, keep the desktop unlocked and grants current, and never run native/capture/effect mutations concurrently; each full suite needs fresh disposable fixtures. See `TESTING.md` for exact suite scope and `VISUAL_EFFECTS_VALIDATION.md` for destructive-close warnings/manual steps.

## Separate experimental Kinetiq build and run

The updated 5 November contract requests the **real external Kinetiq.app**, with optional private AX mapping/event-tap/click replay/off-screen parking. It is not AETHER's manual preview or a library linked into its targets. See `KINETIQ_ENGINE.md` for authorization, warnings and licensing.

Validated `bash Scripts/build-kinetiq.sh [sourcecheckout]` defaults to sibling `/Users/lorenzov/dev/Wobbly`, validates checkout/resources/licenses/identity, refuses rebuilding a running engine and delegates to original upstream. Default `SIGN_IDENTITY=-` is local ad-hoc, not Developer ID/notarization or persistent grants. `/tmp/aether-kinetiq-engine-build.log` exits 0: actual **0.1.27/build 28**, `io.github.invernomut0.Kinetiq`; vtool verifies both Mach-O **arm64/x86_64 minos 14.0**. Original source stays unchanged/clean at HEAD `0e1b2a2d22cf77b74bdc595d40c79f842e3af807`; actual upstream tests **74/74**, no failures (`/tmp/aether-kinetiq-upstream-tests.log`, exit 0). Retain upstream Swift 5 concurrency/deprecated x86 SDK warnings; no engine Swift 6 claim.

Output stays **`<sourcecheckout>/build/Kinetiq.app`**, outside AETHER.app and its distributed binaries. Do not copy upstream sources/shaders/assets into AETHER or unilaterally change its license. Retain Kinetiq's GPL-3.0-or-later LICENSE/NOTICE, third-party notices and CC-BY-4.0 texture attribution in the original checkout; future bundling/redistribution requires explicit licensing review, not an assumed separate-process exemption.

Select trusted app in **Effects**, check consent and **Start / Connect**. AETHER bootstrap/selection/Refresh stay passive; **Start / Connect explicitly launches or connects**, possibly showing Kinetiq's own AX/Recording prompts. Grants do not transfer. Configure wave menu/Setup Close (nil is Off). No readiness/settings IPC; process existence is not effects proof and AETHER budgets/exclusions/Reduce Motion do not transfer.

Start/Stop waits 10s; cancellation cannot revoke OS requests, retained pending/late ownership blocks replacement. Normal verified termination only; Kinetiq survives AETHER exit, and restoration needs observation. Save work/use disposables. RuntimeModel admission/recheck after configuration await blocks focus/move/capture/effects, including independent instances; passive refresh allowed, visible panels observe every 500ms. **Not a cross-process IPC lock**: independent start during in-flight work is not atomically prevented. Finish/cancel AETHER work before external launch. Stop Kinetiq before diagnostic suites.

`AETHER_RUN_KINETIQ_INTEGRATION=1` final run passed **7/7 XCTest**, zero skips, 1.595s: actual runtime admission plus launch/connect/normal exit, fresh Lab `--m1-fixtures`/Effect Disposable. It does not automate drag/close/readiness or arbitrary late/refused-quit timing. Run separately from mutation suites; retain failures/skips. See visual validation for exact scope.

### 1.0.8/build 9 locally validated
Owner: **AETHER engineering**. Verified final default **53 functions / 58 cases passed**, 34 skipped functions; native **17/17**, effects **6 functions / 7 cases passed**, capture **22 functions / 26 cases passed** with two denial skips, lifecycle **7/7**. Exact logs/times and fresh explicit five-profile merge are in `VISUAL_EFFECTS_VALIDATION.md`; line TOTAL **64.48%** (4,491 lines / 1,595 uncovered) includes newly linked Interface/Effects, not a like-for-like 1.0.7 decline or shader/branch coverage.

All four helpers (`Scripts/build-kinetiq.sh`, `Scripts/test-effect-integration.sh`, `Scripts/test-capture-integration.sh`, `Scripts/test-window-integration.sh`) passed shell syntax checks and were invoked with the real Kinetiq app launched from its exact trusted bundle. Each exited **2** with an explicit quit/stop Kinetiq message before any operation started; enclosing check **`HELPER_GUARDS_EXIT0`**. Identity-checked selected `NSRunningApplication` normal termination and actual exit were verified; no forced kill. Native/capture preserve instrumentation with `--enable-code-coverage`. After final Swift validation, only shell guards (separately syntax/integration checked) and documentation changed.

Final local receipt (**5 November, approximately 12:45**): both exact Debug bundles completed NSWorkspace launch, **AETHER PID 69118**, **Test Lab PID 69116** (`--m1-fixtures`), with CG-owned **AETHER Effect Disposable** and **AETHER Refuses Close** titles verified and **`KINETIQ_RUNNING=false`**. Both versions were verified as **1.0.8/build 9**. `qlmanage -r`, `qlmanage -r cache` and the Finder Debug-directory update completed; editor diagnostics were empty and `git diff --check` clean at the verified checkpoint.

### Repository publication receipt
Track the **1.0.8 atomic commit/push and final review** in `TODO.md`; record the actual Git commit and origin verification after they occur. No current publication is asserted by local validation. Repository publication is not milestone acceptance or release readiness. **Remote CI remains a separate Review item**, as do manual effects/indicator/restoration/platform checks.

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
- Run the opted-in effects suite on fresh fixtures, sequentially with native/capture regression; retain refusal/unconfirmed-close failures rather than accepting a dissolve without confirmed close.
- Complete `VISUAL_EFFECTS_VALIDATION.md`: manual indicator observations, disposable Wobble/Close, Reduce Motion, Stop/Escape/navigation, focus/input and cleanup. Target pacing is not a measured frame-rate result.
- Run multi-display and sleep/wake tests.
- Verify permissions and revocation behavior.
- Verify no orphan overlays.
- Inspect hardened runtime and entitlements.
- Sign, notarize and staple.
- Produce changelog and known limitations.
- Review Kinetiq as a separate optional experiment: verified trusted external bundle, explicit consent/own permissions, no autostart/TCC editing/indicator bypass, active/pending/independent-instance interlocks and no forced termination. Retain separate lifecycle and manual drag/close/normal-quit/native-restoration evidence. Its private path remains disabled by default and cannot be a stable release dependency; do not bundle or relicense without explicit license/attribution review.

## Current release gate status (2026-11-05)
- M0 and M1 are locally accepted.
- **1.0.8/build 9 locally validated**: build/tests/compatible coverage/both built versions, exact app relaunch/refresh and all four active-engine helper guards are verified above. Repository publication receipts are tracked separately from remote CI Review; manual engine/physical acceptance stays Review. See `VISUAL_EFFECTS_VALIDATION.md`.
- **Historical 1.0.7/build 8** validation, both app builds, verified Info.plists, relaunches and Quick Look/Finder refresh passed. Its snapshot/stream proof, coverage and retained failures remain in `M2_VALIDATION.md`, not current evidence.
- Full **M2 physical/platform gate is NOT accepted**, nor is Living Window Gate 0: indicators, physical scanout, recovery, SDK faults and macOS 14 runtime remain pending. The updated 5 November request permits the optional real external Kinetiq experiment plus the separate diagnostic slice, not full milestone acceptance or release readiness.
