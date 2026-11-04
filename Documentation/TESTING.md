# Testing Strategy

## M0 automated baseline
Run `swift test --enable-code-coverage` or `bash Scripts/validate.sh`. Original XCTest suites cover models, layouts, easing and springs. New Swift Testing suites cover configuration initialization, the shipped defaults, atomic round trips, legacy migration, unsupported schemas, preservation of invalid files, restart/retry and cancellation before bootstrap. Tests use actual filesystem repositories and passive system permission checks; they never grant access or display prompts.

The configuration fixture is the repository's `Configuration/DefaultConfiguration.json`, located relative to the test source. Temporary files are removed after each test. No mock services or generated pixel captures are used. Build verification is not a substitute for the M1/M2 integration gates below.

For startup smoke verification, launch both built apps, confirm AETHER reports M0 readiness and schema 1, and confirm no capture or permission request starts automatically. Press permission buttons only when you want to grant those capabilities. Ad-hoc signing may require regranting access after rebuilds.

`bash Scripts/coverage.sh` aggregates all macOS test executables using the merged coverage profile. Do not rely on SwiftPM's `AETHER.json` alone on Xcode 27.2: its export can contain only the last suite. Reported coverage is not a claim that unimplemented capture/rendering paths have been tested.

## Test layers
### M1 native integration
`swift test --filter NativeWindowTests` runs read-only desktop discovery, pre-cancellation and geometry conversion on a real NSWindow. Eleven mutation/fixture tests are opt-in and skipped by default, including in CI. Headless/unauthorized hosts must not be reported as having passed the live gate.

On a local interactive Mac with Accessibility explicitly granted to the test host, quit Test Lab and run `bash Scripts/test-window-integration.sh`. It builds both apps, launches Test Lab with `--m1-fixtures`, and runs `AETHER_RUN_WINDOW_INTEGRATION=1 swift test --filter NativeWindowTests`. No permission prompts or capture are initiated. A missing consent or missing fixture fails the opted-in tests rather than silently skipping them.

The suite uses real external NSWindows, not self-process AX (which can deadlock MainActor), mock controllers or fabricated desktop datasets. It verifies distinct handles and generations, exact-target move/resize and restoration, focus readback, fixed-size rejection, equal-title/equal-frame ambiguity, forged handles, invalid geometry, pre-cancellation, disappearance and correlation from observed AX metadata. CG titles may be redacted without Screen Recording; overlap fixtures are located from their real AX geometry instead. A disposable fixture is closed; relaunch fixtures before repeating the entire opted-in suite. Other applications are never mutated.

Geometry requires matching AX and CG frames across successive observations. Regression coverage includes moving before growth to avoid AppKit's display-edge clamp and waiting for WindowServer publication. Failed geometry transactions may be partial; the service invalidates the handle and requires refresh, rather than automatically overwriting newer user state.

### Remaining layers
- Unit: pure models, geometry, layout trees, physics, easing, serialization.
- Integration: capture lifecycle, overlay transaction, permission changes, window reconciliation.
- Rendering: shader compilation, texture formats, alpha, mesh, particle and pass validation.
- UI: onboarding, permissions, settings, effect library and diagnostics.
- Performance: frame time, GPU/CPU, memory, capture latency and soak.

## Test Lab
A separate macOS app creates real deterministic windows for M1:
- standard resizable (A/B/disposable)
- fixed-size
- identical overlapping title/frame pairs (intentionally read-only)

Additional fixture coverage is still required for later milestones:
- transparent
- high-frequency changing content
- video-like animation
- large and small geometry
- multiple windows in one process
- fullscreen test window (manual/controlled)

## Failure injection
- Permission denied/revoked.
- Capture stream stops.
- Window disappears mid-transition.
- AX set operation rejected.
- Display disconnected.
- App sleeps/wakes.
- GPU resource allocation fails.
- Renderer suspended.
- User cancels animation.
- App is terminated during overlay presentation.

## Required assertions
- Native window remains recoverable.
- Overlay cleanup is idempotent.
- Capture session is stopped.
- GPU resources are released.
- Errors are typed and diagnosable.
- No stale frame is presented after window identity changes.
