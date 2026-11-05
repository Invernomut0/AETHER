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
M2 tests include real capture-path and rendering-path checks. Final local validation of the current normal snapshot and explicit stream/overlay paths passed, including three complete post-fix capture suites. Broader platform and Living Window animation acceptance remain pending.

- Capture component tests cover observed desktop request validation, privacy exclusions, passive denial when a registered handle is available, callback deadline/cancellation behavior and idle cleanup. Actual screenshot image conversion, stream sample conversion, bounded delivery and active teardown remain consent-dependent, not covered by default tests.
- Live ScreenCaptureKit tests are opt-in and require explicit enablement plus pre-granted host permissions. If explicitly enabled without grant, they fail by design rather than being treated as fake passes.
- `WindowPreviewCoordinator.preview(..., mode: .snapshot)` defaults to **Snapshot 5s**: one `SCScreenshotManager.captureImage`, no `SCStream` or screenshot refresh loop, immutable BGRA at most 1600px per edge. Successful snapshot SDK/lease ownership is released before static Metal presentation. Freshness is checked only before first presentation; the retained texture is intentionally static for at most 5s with existing native/permission monitors. `framesPresented == 1` means GPU completion, not physical scanout or continuously fresh content.
- Snapshot waiter cancellation/5s timeout does not cancel SDK enumeration/image callbacks. Cleanup waits independently for up to 3s, retaining ownership until actual completion; one mutually exclusive snapshot/stream lease blocks replacement while cleanup is unconfirmed. Expected ownership/cancellation behavior is a contract, not certification of every callback order.
- Both preview monitors check permission/secure input and exact CG ID/PID/on-screen visibility every 100ms before AX IPC. Callers already validate after capture/before presentation; periodic AX validation starts 500ms after monitor start, then repeats every 500ms plus bounded AX latency. This avoids an immediate duplicate query racing native minimization without removing generation/geometry checks or accepting timeouts as interruption.
- **Live diagnostic** explicitly uses continuous 30fps `SCStream` capture with OS recording indicators expected. Screen Recording is required in both modes. No private flags, suppression or bypass is used; absence of macOS indicators is not guaranteed. Compare the public APIs via the pinned source and Apple links in `M2_VALIDATION.md`, not by copying GPL code or adopting Wobbly's launch warmup/off-screen parking.
- The parametrized target-interruption test waits for the first real GPU-completed frame, moves/minimizes/closes only a uniquely matched external Test Lab target, checks typed interruption and overlay removal, and runs another preview through the **same** coordinator while the mutation remains in effect. Cleanup failures/timeouts/cancellation do not count as expected interruption. Non-disposable fixture state is restored on success or error. Closure consumes a separate `M2 Fixture Capture Disposable`; relaunch Test Lab before repeating the complete capture suite.
- Pending-start cancellation and Stop tests observe an actual owned inactive session ID through an internal diagnostic, require cancellation rather than timeout/cleanup error, then require another fresh complete BGRA frame through the same owner. The concurrent test runs three cycles with two Start tasks (one session/one rejection), cancelled/normal Stop callers, unique IDs, no ownership/activity and bounded stream termination. No SDK callback timing or queue blocking is injected; inactive ownership observation is not certification of every SDK callback phase/order.
- Real Metal tests use an actual `Terminal.app` icon `CGContext` BGRA upload plus a real `NSWindow`; they validate GPU command completion, visible non-activating panel behavior, input passthrough/focus invariants, and idempotent removal.
- Default test mode continues to use real desktop descriptors and host permissions with conditional preconditions; "no eligible" output means coverage was not exercised in that environment.

### Final current snapshot validation — passed locally

Source inventory is **60 functions / 69 expanded cases**. Final default mode passed **34 functions / 39 cases executed with 26 function skips**: counted from **6 XCTest + 28 Swift Testing function passes** and 26 explicit skip lines, not suite totals that include skips. `/tmp/aether-snapshot-final-validation.log` ends with **Package and app validation completed**, including both app builds with Info.plists verified as **1.0.7/build 8**. This is not a single all-opt-ins run.

A prior validation/app-build pass (`/tmp/aether-snapshot-validation.log`) and focused snapshot **4-function / 5-case pass** (`/tmp/aether-snapshot-focused-live-fixed.log`) predate two later added functions and are intermediate evidence only. Retain the earlier focused failure (`/tmp/aether-snapshot-focused-live.log`): AX cancellation intentionally invalidated the generation; the test now refreshes and reselects the **same CG ID/PID** for recovery, without relaxing production identity checks.

Both `/tmp/aether-snapshot-full-live-{1,2}.log` failed the snapshot minimize AX-query timeout. The first CG-only guard attempt (`/tmp/aether-snapshot-visibility-fixed.log`) also failed; it was not the complete fix. `/tmp/aether-snapshot-minimize-diagnostic.log` locates the failure in the preview interruption result; source inspection identifies immediate post-GPU monitor AX validation racing native minimization. The final combination of exact CG visibility before AX and next AX at 500ms after monitor start passed focused movement/minimization **one function / two cases** (`/tmp/aether-snapshot-minimize-fixed.log`), then three complete suites. Timeout is still a failure, budgets were not increased and no SDK delay was injected.

Capture inventory is **24 functions / 28 expanded cases**. `/tmp/aether-snapshot-full-live-{3,4,5}.log` each passed **22 functions / 26 cases executed**, with **two inapplicable denial skips**, in **21.282s / 21.126s / 21.150s** respectively. Separate `/tmp/aether-snapshot-native.log` passed **14/14**, **zero skips**, in **3.050s**. All live runs used pre-granted AX/Recording, secure input off and controlled Lab fixtures, fresh per full run; native/capture mutations were never concurrent.

Fresh same-instrumentation `/tmp/aether-snapshot-{default,capture-5,native}.profdata` were preserved and explicitly merged. `/tmp/aether-snapshot-final-coverage.log` reports final **line** coverage: snapshot lease **95.20%**, stream lease **94.95%**, capture coordinator **92.86%**, preview **94.12%**, Metal presenter **87.86%**, **TOTAL 84.49%**. Earlier pre-snapshot coverage remains historical, not final current evidence. Local validation, bundle-plist verification, both app relaunches and Quick Look/Finder refresh completed; see `M2_VALIDATION.md` for relaunch evidence. Remote CI review is separate and pending. Physical display/OS-indicator absence (not visually certified), scanout, manual recovery, SDK faults and macOS 14 runtime checks remain pending; M3 has not started.

### Historical evidence (before the normal snapshot path)

Historical 1.0.4 default validation on the locked host passed 33 functions / 38 expanded cases with 17 skips. After explicit Recording consent, three consecutive capture suites passed with 12 functions executed and two denial tests inapplicable; separate native regression passed 14/14. The initial live suite failed its unchanged focus assertion when macOS UserNotificationCenter became frontmost. Preserve such failures and repeat after the system notification is resolved; do not suppress notifications, bypass consent or weaken focus assertions. See `M2_VALIDATION.md` for evidence and remaining manual checks.

Final 1.0.5 default validation passed 34 functions / 39 cases with 16 skips; the separate consented coverage rerun passed all 12 applicable capture functions. Recheck that Test Lab is running after rebuilding: an intervening attempt correctly failed all three live prerequisites when the fixture process was absent. Do not combine native mutation tests and live capture tests concurrently against the same fixtures.

Version 1.0.6 passes default 34 functions / 39 cases with 17 skips; the new parametrized opt-in raises inventory to 51 functions / 58 cases. Four post-fix live suites pass 13 functions / 15 cases each, with two denial skips, and separate M1 passes 14/14. Generate coverage immediately after coverage-enabled executions: rebuilding test binaries without coverage invalidates the corresponding profile. The final coherent live report measures lease 93.56% and preview 93.39% line coverage, with an observed real already-stopped error; other stop failures remain untested. Exact logs, failed closure baseline and rejected stale-profile report are recorded in `M2_VALIDATION.md`.

Historical pre-snapshot 1.0.7 added three opt-in functions, raising its inventory to 54 functions / 61 cases. Default validation passed 34 functions / 39 cases with 20 skips; three complete stream suites passed 16 functions / 18 cases with two denial skips each, and separate M1 passed 14/14. The Stop-during-startup test first reproduced a real callback timeout, fixed by queue-owned startup cancellation without dropping unconfirmed SDK ownership. This is not validation of the current snapshot inventory; see `M2_VALIDATION.md` for the failed baseline and exact evidence.

Coverage caveat: a filtered `swift test --enable-code-coverage` can replace `default.profdata` even when binaries remain unchanged. For combined default/native/capture coverage, preserve each generated profile **before** the next invocation and explicitly merge compatible profiles with `xcrun llvm-profdata merge -sparse`; then report all test executables against the merged profile. `Scripts/coverage.sh` reports the current profile only, not prior execution history. Do not merge profiles from differently instrumented/rebuilt binaries or run native/capture mutations concurrently. The **historical pre-snapshot** 1.0.7 merge measured stream lease 94.95%, capture coordinator 89.47%, preview 93.39%, Metal presenter 87.86%, aggregate 81.62% line coverage; it is not final coverage of the snapshot path. Untested failure branches remain pending.

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
- Snapshot ownership is released before successful presentation; stream teardown is confirmed. Unconfirmed callbacks/cleanup retain ownership rather than permitting replacement.
- GPU resources remain owned until actual completion, then are released; a timeout alone is not release confirmation.
- Errors are typed and diagnosable.
- No frame is first presented after window identity changes; static snapshot retention is intentional, with identity/geometry and permission monitors still active.

For M2 gate acceptance, assertions must also include a real consented capture frame path from ScreenCaptureKit to overlay presentation and removal. Do not infer physical scanout or absent OS indicators from GPU completion or a one-shot API.
