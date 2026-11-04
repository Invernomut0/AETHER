# Testing Strategy

## M0 automated baseline
Run `swift test --enable-code-coverage` or `bash Scripts/validate.sh`. Original XCTest suites cover models, layouts, easing and springs. New Swift Testing suites cover configuration initialization, the shipped defaults, atomic round trips, legacy migration, unsupported schemas, preservation of invalid files, restart/retry and cancellation before bootstrap. Tests use actual filesystem repositories and passive system permission checks; they never grant access or display prompts.

The configuration fixture is the repository's `Configuration/DefaultConfiguration.json`, located relative to the test source. Temporary files are removed after each test. No mock services or generated pixel captures are used. Build verification is not a substitute for the M1/M2 integration gates below.

For startup smoke verification, launch both built apps, confirm AETHER reports M0 readiness and schema 1, and confirm no capture or permission request starts automatically. Press permission buttons only when you want to grant those capabilities. Ad-hoc signing may require regranting access after rebuilds.

`bash Scripts/coverage.sh` aggregates all macOS test executables using the merged coverage profile. Do not rely on SwiftPM's `AETHER.json` alone on Xcode 27.2: its export can contain only the last suite. Reported coverage is not a claim that unimplemented capture/rendering paths have been tested.

## Test layers
- Unit: pure models, geometry, layout trees, physics, easing, serialization.
- Integration: capture lifecycle, overlay transaction, permission changes, window reconciliation.
- Rendering: shader compilation, texture formats, alpha, mesh, particle and pass validation.
- UI: onboarding, permissions, settings, effect library and diagnostics.
- Performance: frame time, GPU/CPU, memory, capture latency and soak.

## Test Lab
A separate macOS app should create deterministic windows:
- standard resizable
- fixed-size
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
