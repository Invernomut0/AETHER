# Testing Strategy

## M0 automated baseline
Run `swift test --enable-code-coverage` or `bash Scripts/validate.sh`. Original XCTest suites cover models, layouts, easing and springs. New Swift Testing suites cover configuration initialization, the shipped defaults, atomic round trips, legacy migration, unsupported schemas, preservation of invalid files, restart/retry and cancellation before bootstrap. Tests use actual filesystem repositories and passive system permission checks; they never grant access or display prompts.

The configuration fixture is the repository's `Configuration/DefaultConfiguration.json`, located relative to the test source. Temporary files are removed after each test. No mock services or generated pixel captures are used. Build verification is not a substitute for the M1/M2 integration gates below.

For startup smoke verification, launch both built apps, confirm AETHER reports M0 readiness and schema 1, and confirm no capture or permission request starts automatically. Press permission buttons only when you want to grant those capabilities. Ad-hoc signing may require regranting access after rebuilds.

`bash Scripts/coverage.sh` aggregates all macOS test executables using the merged coverage profile. Do not rely on SwiftPM's `AETHER.json` alone on Xcode 27.2: its export can contain only the last suite. Reported coverage is not a claim that every consent-dependent capture path has been validated live.

## Test layers
### M1 native integration
`swift test --filter NativeWindowTests` runs read-only desktop discovery, pre-cancellation and geometry conversion on a real NSWindow. Eleven mutation/fixture tests are opt-in and skipped by default, including in CI. Headless/unauthorized hosts must not be reported as having passed the live gate.

On a local interactive Mac with Accessibility explicitly granted to the test host, quit Test Lab and run `bash Scripts/test-window-integration.sh`. It builds both apps, launches Test Lab with `--m1-fixtures`, and runs `AETHER_RUN_WINDOW_INTEGRATION=1 swift test --filter NativeWindowTests`. No permission prompts or capture are initiated. A missing consent or missing fixture fails the opted-in tests rather than silently skipping them.

The suite uses real external NSWindows, not self-process AX (which can deadlock MainActor), mock controllers or fabricated desktop datasets. It verifies distinct handles and generations, exact-target move/resize and restoration, focus readback, fixed-size rejection, equal-title/equal-frame ambiguity, forged handles, invalid geometry, pre-cancellation, disappearance and correlation from observed AX metadata. CG titles may be redacted without Screen Recording; overlap fixtures are located from their real AX geometry instead. A disposable fixture is closed; relaunch fixtures before repeating the entire opted-in suite. Other applications are never mutated.

Geometry requires matching AX and CG frames across successive observations. Regression coverage includes moving before growth to avoid AppKit's display-edge clamp and waiting for WindowServer publication. Failed geometry transactions may be partial; the service invalidates the handle and requires refresh, rather than automatically overwriting newer user state.

### M2 capture/overlay implementation coverage
M2 tests include real capture-path and rendering-path checks. The consented local capture/overlay proof passed; broader platform and Living Window animation acceptance remain pending.

- Capture component tests cover observed desktop request validation, privacy exclusions, passive denial when a registered handle is available, callback deadline/cancellation behavior and idle cleanup. Actual ScreenCaptureKit sample conversion, bounded stream delivery and active teardown remain consent-dependent, not covered by default tests.
- Live ScreenCaptureKit tests are opt-in and require explicit enablement plus pre-granted host permissions. If explicitly enabled without grant, they fail by design rather than being treated as fake passes.
- The parametrized target-interruption test waits for the first real GPU-completed frame, moves/minimizes/closes only a uniquely matched external Test Lab target, checks typed interruption and overlay removal, and runs another preview through the **same** coordinator while the mutation remains in effect. Cleanup failures/timeouts/cancellation do not count as expected interruption. Non-disposable fixture state is restored on success or error. Closure consumes a separate `M2 Fixture Capture Disposable`; relaunch Test Lab before repeating the complete capture suite.
- Real Metal tests use an actual `Terminal.app` icon `CGContext` BGRA upload plus a real `NSWindow`; they validate GPU command completion, visible non-activating panel behavior, input passthrough/focus invariants, and idempotent removal.
- Default test mode continues to use real desktop descriptors and host permissions with conditional preconditions; "no eligible" output means coverage was not exercised in that environment.

Historical 1.0.4 default validation on the locked host passed 33 functions / 38 expanded cases with 17 skips. After explicit Recording consent, three consecutive capture suites passed with 12 functions executed and two denial tests inapplicable; separate native regression passed 14/14. The initial live suite failed its unchanged focus assertion when macOS UserNotificationCenter became frontmost. Preserve such failures and repeat after the system notification is resolved; do not suppress notifications, bypass consent or weaken focus assertions. See `M2_VALIDATION.md` for evidence and remaining manual checks.

Final 1.0.5 default validation passed 34 functions / 39 cases with 16 skips; the separate consented coverage rerun passed all 12 applicable capture functions. Recheck that Test Lab is running after rebuilding: an intervening attempt correctly failed all three live prerequisites when the fixture process was absent. Do not combine native mutation tests and live capture tests concurrently against the same fixtures.

Version 1.0.6 passes default 34 functions / 39 cases with 17 skips; the new parametrized opt-in raises inventory to 51 functions / 58 cases. Four post-fix live suites pass 13 functions / 15 cases each, with two denial skips, and separate M1 passes 14/14. Generate coverage immediately after coverage-enabled executions: rebuilding test binaries without coverage invalidates the corresponding profile. The final coherent live report measures lease 93.56% and preview 93.39% line coverage, with an observed real already-stopped error; other stop failures remain untested. Exact logs, failed closure baseline and rejected stale-profile report are recorded in `M2_VALIDATION.md`.

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
- independent M2 capture disposable (closed by the live capture suite, not by M1)

Additional fixture coverage is still required for later milestones:
- transparent
- high-frequency changing content
- video-like animation
- large and small geometry
- multiple windows in one process
- fullscreen test window (manual/controlled)

Run `bash Scripts/test-capture-integration.sh` for the M2 live helper. It requires:
- An unlocked desktop with secure input finished. Both integration scripts conservatively reject secure input before building; they never unlock the session or change TCC.
- Test Lab not already running.
- Accessibility and Screen Recording already granted to the test host.
- App builds launched as fixtures.
- `AETHER_RUN_CAPTURE_INTEGRATION=1` opt-in for capture pipeline live tests.

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

For M2 gate acceptance, assertions must also include a real consented capture frame path from ScreenCaptureKit to overlay presentation and removal.
