# Testing Strategy

## Current validation status — 1.0.8/build 9
**1.0.8/build 9 locally validated.** Verified receipts: default **53 functions / 58 cases passed** (19 XCTest + 34 Swift Testing), **34 skipped functions** (one Kinetiq opt-in XCTest + 33 Swift Testing); package Swift 6 build and both Xcode apps pass, both built Info.plists **1.0.8/build 9**. This is parsed execution evidence, not an unchecked global inventory. Current native **17/17**, zero skips, **3.877s**; capture **22 functions / 26 cases**, two denial skips (selected inventory 24/28), **21.408s**; effects **6 functions / 7 cases**, zero skips, **9.880s**. All `/tmp/aether-kinetiq-final-{validation,native,capture,effects}.log` exit 0. Exact local app relaunches, Quick Look/Finder refresh and all four active-engine helper guards are verified. Manual indicators remain user-pending, not inferred from GPU completion. Full receipts: `VISUAL_EFFECTS_VALIDATION.md`; Git publication tracking is separate from remote CI Review in `TODO.md`.

The updated 5 November request selects actual external **Kinetiq.app**, permits optional private AX/event-tap/click replay/off-screen parking, disabled by default in AETHER. Earlier Wobble/Close remains a separate diagnostic fallback, not Kinetiq. Real external universal build and original upstream **74/74** tests pass; original Swift 5 concurrency/deprecated x86 SDK warnings remain. Full **M2 physical/platform, M3/M4 and Living Window gates remain NOT accepted**; manual engine behavior stays Review. See `KINETIQ_ENGINE.md`.

## M0 automated baseline
Run `swift test --enable-code-coverage` or `bash Scripts/validate.sh`. Original XCTest suites cover models, layouts, easing and springs. New Swift Testing suites cover configuration initialization, the shipped defaults, atomic round trips, legacy migration, unsupported schemas, preservation of invalid files, restart/retry and cancellation before bootstrap. Tests use actual filesystem repositories and passive system permission checks; they never grant access or display prompts.

The configuration fixture is the repository's `Configuration/DefaultConfiguration.json`, located relative to the test source. Temporary files are removed after each test. No mock services or generated pixel captures are used. Build verification is not a substitute for the M1/M2 integration gates below.

For startup smoke verification, launch both built apps, confirm AETHER reports M0 readiness and schema 1, and confirm no capture or permission request starts automatically. Press permission buttons only when you want to grant those capabilities. Ad-hoc signing may require regranting access after rebuilds.

`bash Scripts/coverage.sh` aggregates all macOS test executables using the merged coverage profile. Do not rely on SwiftPM's `AETHER.json` alone on Xcode 27.2: its export can contain only the last suite. Reported coverage is not a claim that every consent-dependent capture path has been validated live.

## Test layers
### External Kinetiq lifecycle — passed locally, bounded scope

`Tests/AETHERCoreTests/KinetiqEngineTests.swift`: **7/7 XCTest**, zero skips, **1.595s** (`/tmp/aether-kinetiq-final-live.log`, exit 0), six passive + one opt-in lifecycle test. Passive cases use real Terminal.app rejection, actual Kinetiq metadata/resources, consent, invalid-bundle no-launch and pre-cancelled start/stop. Record any missing-bundle skips in future runs, not passes.

`AETHER_RUN_KINETIQ_INTEGRATION=1` requires fresh controlled Test Lab **`--m1-fixtures`**, including **AETHER Effect Disposable**. It verifies real launch/same-PID connect, independent manager discovery without takeover, refused consent to connect an existing instance and normal Stop/exit. Via `@testable AETHERInterface`, actual `AetherRuntimeModel` rejects `.focus`, `.setFrame`, `.preview`, `.live`, `.effect(.wobble)` and `.effect(.dissolveClose)` with **Stop Kinetiq**; `.refresh` succeeds and fixture frame/on-screen state stays unchanged. Interface is a **CoreTests-only dependency**, not production Core (no cycle). Kinetiq's own prompts are possible; the test skips a user's pre-existing engine and registers normal teardown after failure. No force kill. Retain failures and inspect uncertain cleanup.

No global input injection or native fixture mutation is intended by this interlock test. It **does not** select an effect, drag/replay clicks, close a disposable, grant permissions or certify event-tap/shader readiness. PID existence/exit is not proof of visible effects/restoration. AETHER policies do not govern the external engine.

Run only on a consented interactive host with saved work/trusted Kinetiq, separately from mutation suites. Stop Kinetiq before diagnostics. RuntimeModel admission and its post-configuration-await recheck plus 500ms visible-panel observation are **not a cross-process IPC lock**: an independent engine start during an already-in-flight action is not atomically prevented. Finish/cancel AETHER work before external launch. Pending/late callbacks, refused/timed-out quit timing, private-OS and displaced-window recovery remain manual/source-contract review; no SDK delays were forcibly injected.

Manual engine validation remains separate: wave-menu Enabled/Drag from Title Bar, Setup Close explicitly selected (nil is Off), disposable drag/close, indicators, motion/exclusions, input and observed restoration. Follow `VISUAL_EFFECTS_VALIDATION.md`; verified automation does not certify these Review items or publication.

All four helpers (`Scripts/build-kinetiq.sh`, `Scripts/test-effect-integration.sh`, `Scripts/test-capture-integration.sh`, `Scripts/test-window-integration.sh`) passed `bash -n` and were invoked with the real Kinetiq app running from its exact trusted bundle. Each returned **exit 2**, explicitly requesting quit/stop Kinetiq before any build, permission, fixture or test operation started; enclosing check **`HELPER_GUARDS_EXIT0`**. The selected identity-checked `NSRunningApplication` then terminated normally, with actual exit confirmed and no forced kill. This guard preflight is not an atomic IPC lock or restoration proof. Native/capture use **`--enable-code-coverage`** to preserve instrumentation compatibility. AETHER bootstrap/selection/Refresh stay passive; explicit Kinetiq Start/Connect can show its own prompts.

### M1 native integration
`swift test --filter NativeWindowTests` includes desktop discovery/pre-cancellation, geometry conversion on a real NSWindow, backward-compatible `canClose` Codable checks derived from discovery, and a real ordered-out NSWindow proving off-screen membership is not closure. Mutation/fixture tests are opt-in and skipped by default, including in CI. Headless/unauthorized hosts must not be reported as having passed the live gate.

On a local interactive Mac with Accessibility explicitly granted, stop Kinetiq, quit Test Lab and run `bash Scripts/test-window-integration.sh`. It builds both apps, launches `--m1-fixtures` and runs `AETHER_RUN_WINDOW_INTEGRATION=1 swift test --enable-code-coverage --filter NativeWindowTests`. No permission prompts or capture are initiated. Missing consent/fixtures fail opted-in tests rather than silently skipping.

The suite uses real external NSWindows for AX, not self-process AX (which can deadlock MainActor), mock controllers or fabricated desktop datasets. It verifies distinct handles and generations, exact-target move/resize and restoration, focus readback, fixed-size rejection, equal-title/equal-frame ambiguity, forged handles, invalid geometry, pre-cancellation, disappearance and correlation from observed AX metadata. The new native `close(_:)` case verifies exact Effect Disposable generation/PID disappearance from a full CG inventory, surviving sibling windows/process, stale/forged receipt rejection and pre-cancel no-close. It uses **`AETHER_RUN_WINDOW_INTEGRATION=1`**, not a separate native-close test variable. CG titles may be redacted without Screen Recording; overlap fixtures are located from their real AX geometry instead. M1 and Effect disposables are consumed; relaunch fresh fixtures before repeating a full suite or switching to the effect suite. Other applications are never mutated.

Geometry requires matching AX and CG frames across successive observations. Regression coverage includes moving before growth to avoid AppKit's display-edge clamp and waiting for WindowServer publication. Failed geometry transactions may be partial; the service invalidates the handle and requires refresh, rather than automatically overwriting newer user state.

### M2 capture/overlay implementation coverage
M2 tests include real capture/rendering paths. Current 1.0.8 regression passed **22 functions / 26 cases**, two denial skips, **21.408s**. Historical 1.0.7 three complete post-fix suites remain historical; broader platform and Living Window acceptance remain open.

- Capture component tests cover observed desktop request validation, privacy exclusions, passive denial when a registered handle is available, callback deadline/cancellation behavior and idle cleanup. Actual screenshot image conversion, stream sample conversion, bounded delivery and active teardown remain consent-dependent, not covered by default tests.
- Live ScreenCaptureKit tests are opt-in and require explicit enablement plus pre-granted host permissions. If explicitly enabled without grant, they fail by design rather than being treated as fake passes.
- `WindowPreviewCoordinator.preview(..., mode: .snapshot)` defaults to **Snapshot 5s**: one `SCScreenshotManager.captureImage`, no `SCStream` or screenshot refresh loop, immutable BGRA at most 1600px per edge. Successful snapshot SDK/lease ownership is released before static Metal presentation. Freshness is checked only before first presentation; the retained texture is intentionally static for at most 5s with existing native/permission monitors. `framesPresented == 1` means GPU completion, not physical scanout or continuously fresh content.
- Snapshot waiter cancellation/5s timeout does not cancel SDK enumeration/image callbacks. Cleanup waits independently for up to 3s, retaining ownership until actual completion; one mutually exclusive snapshot/stream lease blocks replacement while cleanup is unconfirmed. Expected ownership/cancellation behavior is a contract, not certification of every callback order.
- Both preview monitors check permission/secure input and exact CG ID/PID/on-screen visibility every 100ms before AX IPC. Callers already validate after capture/before presentation; periodic AX validation starts 500ms after monitor start, then repeats every 500ms plus bounded AX latency. This avoids an immediate duplicate query racing native minimization without removing generation/geometry checks or accepting timeouts as interruption.
- **Live diagnostic** explicitly uses continuous 30fps `SCStream` capture with OS recording indicators expected. Recording is required in both AETHER modes; no indicator flags/suppression/bypass or absence guarantee. The pinned comparison in historical `M2_VALIDATION.md` describes 1.0.7's public-only design, not the updated external Kinetiq contract. Its private mapping/input replay/parking now runs only in the explicitly opted-in external process, without code/assets copied into AETHER. Test AETHER diagnostics with Kinetiq stopped.
- The parametrized target-interruption test waits for the first real GPU-completed frame, moves/minimizes/closes only a uniquely matched external Test Lab target, checks typed interruption and overlay removal, and runs another preview through the **same** coordinator while the mutation remains in effect. Cleanup failures/timeouts/cancellation do not count as expected interruption. Non-disposable fixture state is restored on success or error. Closure consumes a separate `M2 Fixture Capture Disposable`; relaunch Test Lab before repeating the complete capture suite.
- Pending-start cancellation and Stop tests observe an actual owned inactive session ID through an internal diagnostic, require cancellation rather than timeout/cleanup error, then require another fresh complete BGRA frame through the same owner. The concurrent test runs three cycles with two Start tasks (one session/one rejection), cancelled/normal Stop callers, unique IDs, no ownership/activity and bounded stream termination. No SDK callback timing or queue blocking is injected; inactive ownership observation is not certification of every SDK callback phase/order.
- Real Metal tests use an actual `Terminal.app` icon `CGContext` BGRA upload plus a real `NSWindow`; they validate GPU command completion, visible non-activating panel behavior, input passthrough/focus invariants, and idempotent removal.
- Default test mode continues to use real desktop descriptors and host permissions with conditional preconditions; "no eligible" output means coverage was not exercised in that environment.

### Historical 1.0.7/build 8 snapshot validation — passed locally, not current 1.0.8 evidence

Historical 1.0.7 source inventory was **60 functions / 69 expanded cases**. Its final default mode passed **34 functions / 39 cases executed with 26 function skips**: counted from **6 XCTest + 28 Swift Testing function passes** and 26 explicit skip lines, not suite totals that include skips. `/tmp/aether-snapshot-final-validation.log` ends with **Package and app validation completed**, including both app builds with Info.plists verified as **1.0.7/build 8**. This is not a single all-opt-ins run or the current source inventory.

A prior validation/app-build pass (`/tmp/aether-snapshot-validation.log`) and focused snapshot **4-function / 5-case pass** (`/tmp/aether-snapshot-focused-live-fixed.log`) predate two later added functions and are intermediate evidence only. Retain the earlier focused failure (`/tmp/aether-snapshot-focused-live.log`): AX cancellation intentionally invalidated the generation; the test now refreshes and reselects the **same CG ID/PID** for recovery, without relaxing production identity checks.

Both `/tmp/aether-snapshot-full-live-{1,2}.log` failed the snapshot minimize AX-query timeout. The first CG-only guard attempt (`/tmp/aether-snapshot-visibility-fixed.log`) also failed; it was not the complete fix. `/tmp/aether-snapshot-minimize-diagnostic.log` locates the failure in the preview interruption result; source inspection identifies immediate post-GPU monitor AX validation racing native minimization. The final combination of exact CG visibility before AX and next AX at 500ms after monitor start passed focused movement/minimization **one function / two cases** (`/tmp/aether-snapshot-minimize-fixed.log`), then three complete suites. Timeout is still a failure, budgets were not increased and no SDK delay was injected.

Historical 1.0.7 capture inventory was **24 functions / 28 expanded cases**. `/tmp/aether-snapshot-full-live-{3,4,5}.log` each passed **22 functions / 26 cases executed**, with **two inapplicable denial skips**, in **21.282s / 21.126s / 21.150s** respectively. Separate `/tmp/aether-snapshot-native.log` passed **14/14**, **zero skips**, in **3.050s**. All live runs used pre-granted AX/Recording, secure input off and controlled Lab fixtures, fresh per full run; native/capture mutations were never concurrent.

Historical same-instrumentation `/tmp/aether-snapshot-{default,capture-5,native}.profdata` were preserved and explicitly merged. `/tmp/aether-snapshot-final-coverage.log` reports historical **1.0.7 line** coverage: snapshot lease **95.20%**, stream lease **94.95%**, capture coordinator **92.86%**, preview **94.12%**, Metal presenter **87.86%**, **TOTAL 84.49%**. Neither this nor earlier pre-snapshot coverage is current 1.0.8 evidence. Historical local validation, bundle-plist verification, launches and Quick Look/Finder refresh completed; see `M2_VALIDATION.md`. Remote CI review is separate. Physical display/indicator observations, scanout, manual recovery, SDK faults and macOS 14 runtime remain pending; the new M3/M4 development slice does not accept those gates.

### Explicit effects integration — passed locally, manual acceptance pending

This suite covers AETHER's **independent diagnostic fallback**, not Kinetiq's actual model/shaders or global drag/close integration. Kinetiq must be stopped before it runs; its own manual validation and lifecycle opt-in above remain separate.

`bash Scripts/test-effect-integration.sh` is a new opt-in helper. It checks already-granted AX/Recording and secure input, refuses an already-running Test Lab, builds the apps, launches one external Test Lab with `--m1-fixtures`, then enables **`AETHER_RUN_EFFECT_INTEGRATION=1`** for `WindowEffectIntegrationTests` with coverage. It never grants permissions, unlocks the session, installs event taps or closes user documents. Missing consent or fixtures in an opted-in run fail rather than silently passing.

The final run passed **six functions / seven expanded cases**, zero skips, **9.880s** in `/tmp/aether-kinetiq-final-effects.log` (exit 0):

| Function | Real scenario / required assertions |
|---|---|
| `wobbleAndReuse` | Capture/animate, unchanged native geometry/focus, removal and reuse; repeats with configuration Reduce Motion true (system OR config determines effective behavior) |
| `cancellationAndReuse` | Wait for a real GPU-completed frame, Stop/cancel, remove overlay and reuse the same coordinator |
| `nativeMovementInterrupts` | Move fixture after a real frame; effect interrupts without rollback; test itself restores its controlled fixture |
| `privacyAndPreCancellation` (two kinds) | Exclude Test Lab and precancel both wobble/close; no overlay/frame and no native close |
| `refusedCloseDoesNotAnimate` | Real external `AETHER Refuses Close`, `windowShouldClose == false`; typed unconfirmed outcome, native window unchanged, no dissolve/overlay |
| `nativeCloseWithDissolve` | Close only `AETHER Effect Disposable`, assert full CG ID/PID disappearance, GPU frames/removal, then wobble on a surviving fixture through the same owner |

Passed unit/component additions cover analytical lattice/rest/symmetry/coupling, fractional-step determinism, catch-up limits, saturation/recovery, invalid inputs, vertex ABI/bounds, hidden preflight, actual Terminal-icon texture GPU/cache reuse and close capability/full inventory. Automated results are not visual certification; no simulated SDK frames/controllers replace integration.

Never run **native, capture and effect mutation suites concurrently**. They share fixtures, and native/effect suites each consume Effect Disposable. Relaunch fresh Test Lab fixtures between full suites; for manual effect-only repetition use **Open Effect Disposable**. Actual effect tests use a surviving resizable fixture for non-destructive cases; the **manual Wobble/Close demo uses only Effect Disposable**.

Manual tests: follow `VISUAL_EFFECTS_VALIDATION.md`. Observe title/menu bar BEFORE/DURING/AFTER **Snapshot 5s**; Live diagnostic is an optional positive control only, and recent-use indicators can persist. Test confirmation, real close, Reduce Motion, Stop/Escape/navigation, non-key/input-pass-through panels and no-orphan cleanup. `framesPresented > 1` is not achieved 60fps, scanout or absent-indicator evidence. Full SDK fault-order, revocation, unconfirmed-close/cancellation races and physical platform checks still require explicit evidence.

### Current 1.0.8 source-line coverage — explicit compatible merge

Five profiles saved before each next run with compiled source unchanged: `/tmp/aether-kinetiq-final-{default,live,effects,capture,native}.profdata`. Explicit `llvm-profdata merge -sparse` into package `codecov/default.profdata`, then `Scripts/coverage.sh`, produced `/tmp/aether-kinetiq-final-coverage.log`: WindowSnapshotLease **95.20%**, CaptureStreamLease **94.95%**, ScreenCaptureCoordinator **92.86%**, WindowPreviewCoordinator **94.12%**, WindowEffectCoordinator **94.92%**, WobbleSimulation **100%**, MetalOverlayPresenter **90.75%**, WindowAccessibilitySession **89.42%**, KinetiqEngineCoordinator **85.55%**; TOTAL **64.48%** (4,491 lines / 1,595 uncovered). Interface/Effects newly enter the linked test perimeter: not a like-for-like decrease from 1.0.7. No all-branch, shader, scanout or effect-readiness coverage claim. Detailed receipts are in visual validation.

### Historical evidence (before the normal snapshot path)

Historical 1.0.4 default validation on the locked host passed 33 functions / 38 expanded cases with 17 skips. After explicit Recording consent, three consecutive capture suites passed with 12 functions executed and two denial tests inapplicable; separate native regression passed 14/14. The initial live suite failed its unchanged focus assertion when macOS UserNotificationCenter became frontmost. Preserve such failures and repeat after the system notification is resolved; do not suppress notifications, bypass consent or weaken focus assertions. See `M2_VALIDATION.md` for evidence and remaining manual checks.

Final 1.0.5 default validation passed 34 functions / 39 cases with 16 skips; the separate consented coverage rerun passed all 12 applicable capture functions. Recheck that Test Lab is running after rebuilding: an intervening attempt correctly failed all three live prerequisites when the fixture process was absent. Do not combine native mutation tests and live capture tests concurrently against the same fixtures.

Version 1.0.6 passes default 34 functions / 39 cases with 17 skips; the new parametrized opt-in raises inventory to 51 functions / 58 cases. Four post-fix live suites pass 13 functions / 15 cases each, with two denial skips, and separate M1 passes 14/14. Generate coverage immediately after coverage-enabled executions: rebuilding test binaries without coverage invalidates the corresponding profile. The final coherent live report measures lease 93.56% and preview 93.39% line coverage, with an observed real already-stopped error; other stop failures remain untested. Exact logs, failed closure baseline and rejected stale-profile report are recorded in `M2_VALIDATION.md`.

Historical pre-snapshot 1.0.7 added three opt-in functions, raising its inventory to 54 functions / 61 cases. Default validation passed 34 functions / 39 cases with 20 skips; three complete stream suites passed 16 functions / 18 cases with two denial skips each, and separate M1 passed 14/14. The Stop-during-startup test first reproduced a real callback timeout, fixed by queue-owned startup cancellation without dropping unconfirmed SDK ownership. This is not validation of the current snapshot inventory; see `M2_VALIDATION.md` for the failed baseline and exact evidence.

Coverage caveat: a filtered `swift test --enable-code-coverage` can replace `default.profdata` even when binaries remain unchanged. For combined default/native/capture/effect coverage, preserve each generated profile **before** the next invocation and explicitly merge compatible profiles with `xcrun llvm-profdata merge -sparse`; then report all test executables against the merged profile. `Scripts/coverage.sh` reports the current profile only, not prior execution history. Do not merge profiles from differently instrumented/rebuilt binaries or run native/capture/effect mutations concurrently. The **historical pre-snapshot** 1.0.7 merge measured stream lease 94.95%, capture coordinator 89.47%, preview 93.39%, Metal presenter 87.86%, aggregate 81.62% line coverage; it is not final coverage of the snapshot path or current 1.0.8 evidence. Untested failure branches remain pending.

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
- **AETHER Effect Disposable**, separately used by native-close/effect tests; **Open Effect Disposable** reopens it for manual repeats
- **AETHER Refuses Close**, a real native app window whose delegate returns false from `windowShouldClose`; no fabricated close response

Additional fixture coverage is still required for later milestones:
- transparent
- high-frequency changing content
- video-like animation
- large and small geometry
- multiple windows in one process
- fullscreen test window (manual/controlled)

Run `bash Scripts/test-capture-integration.sh` for the M2 live helper. It requires:
- An unlocked desktop with secure input finished. All three native/capture/effect integration helpers conservatively reject secure input before building; they never unlock the session or change TCC.
- Test Lab not already running.
- Accessibility and Screen Recording already granted to the test host.
- App builds launched as fixtures.
- `AETHER_RUN_CAPTURE_INTEGRATION=1` opt-in for capture pipeline live tests.

## Failure scenarios to validate (not a list of completed passes)
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
The assertions below describe AETHER-owned capture/diagnostic operations with Kinetiq stopped. External-engine lifecycle and manual acceptance use the separate Kinetiq contracts above; its parking, capture and motion policies are not inferred from these assertions.

- Non-destructive preview/wobble preserves the native window and user changes, with no automatic rollback.
- For destructive close, the intended native closure is irreversible: confirm exact-target disappearance, not recoverability by rollback. Stop only removes the overlay; unconfirmed close never authorizes animation or automatic retry.
- Overlay cleanup is idempotent.
- Snapshot ownership is released before successful presentation; stream teardown is confirmed. Unconfirmed callbacks/cleanup retain ownership rather than permitting replacement.
- GPU resources remain owned until actual completion, then are released; a timeout alone is not release confirmation.
- Errors are typed and diagnosable.
- No frame is first presented after window identity changes; static snapshot retention is intentional, with identity/geometry and permission monitors still active.

For M2 gate acceptance, assertions must also include a real consented capture frame path from ScreenCaptureKit to overlay presentation and removal. Do not infer physical scanout or absent OS indicators from GPU completion or a one-shot API.
