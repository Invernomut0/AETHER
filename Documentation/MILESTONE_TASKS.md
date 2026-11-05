# Milestone Task Breakdown

Current status: **1.0.8/build 9 locally validated**. Owner: **AETHER engineering**; no delivery dates committed. The 5 November request permits real external Kinetiq's optional private mapping/input replay/parking and the separate diagnostic slice, not full M2/M3/M4/Living Window acceptance. Verified helper/build/actual admission/tests/coverage/built-version/launch/refresh receipts are in `KINETIQ_ENGINE.md` and `VISUAL_EFFECTS_VALIDATION.md`. Git commit/origin verification is tracked in `TODO.md` as a publication receipt, not a milestone/readiness gate; remote CI remains separate Review.

## Real external Kinetiq — locally validated; manual acceptance pending

- [x] Add MainActor `KinetiqEngineCoordinator` for the actual separately installed app, trusted metadata/resources checks (not authentication), explicit consented launch/connect, pending/late callback ownership and 10s waits; normal verified termination only, never force-kill.
- [x] Wire **Effects** to `KinetiqEnginePanel`, warnings/checkbox, app selection, Start/Connect, Stop, Cancel wait, passive Refresh and real wave-menu/Setup guidance. No fake readiness/settings RPC; no Kinetiq source/assets linked/copied.
- [x] Document the updated optional private AX/input replay/parking contract, separate permissions/settings/capture budgets, native restoration risks, continued engine life after AETHER exit and upstream GPL/NOTICE/third-party/CC-BY attribution boundary.
- [x] Final six passive + one opt-in lifecycle: **7/7 XCTest**, zero skips, **1.595s**, actual RuntimeModel six command rejections/passive refresh/unchanged fixture, same-PID connect, independent discovery without takeover, refused consent and normal exit. Fresh Lab `--m1-fixtures`/Effect Disposable required; no global injection/native mutation intended, no drag/close/readiness proof. Interface is CoreTests-only (no production Core cycle).
- [x] Validate `Scripts/build-kinetiq.sh` delegation to unchanged clean upstream HEAD `0e1b2a2d22cf77b74bdc595d40c79f842e3af807`; external **0.1.27/build 28**, actual universal arm64/x86_64 minos 14.0, upstream **74/74**. Original Swift 5/deprecated SDK warnings retained, no engine Swift 6 claim. Implement admission/post-config-await recheck and 500ms visible-panel observation. Not a cross-process IPC lock: finish/cancel before independent start, which is not atomically prevented during in-flight work.
- [x] Final Swift 6/default/both app validation: **53 functions / 58 cases passed** (19 XCTest + 34 Swift Testing), **34 skipped functions** (one Kinetiq opt-in + 33 Swift Testing); both actual built Info.plists **1.0.8/build 9**. Sequential fresh-Lab effects **6 functions / 7 cases passed**, zero skips, 9.880s; capture **22 functions / 26 cases passed**, two denial skips (24 functions / 28 cases selected inventory), 21.408s; native **17/17**, zero skips, 3.877s. All logs exit 0; exact receipts in visual validation.
- [x] Save five compatible default/live/effects/capture/native profiles before next run, source unchanged; explicitly merge. Current line TOTAL **64.48%**, 4,491 lines / 1,595 uncovered, expanded Interface/Effects perimeter, not like-for-like 1.0.7 decrease or branch/shader coverage. Main-workflow diagnostics empty/whitespace clean; four helper syntax checks passed.
- [x] Actual active-engine helper guards: all four build/effect/capture/window helpers invoked against real trusted-path Kinetiq; each exits **2** with explicit quit/stop instruction before any operation starts; enclosing check **`HELPER_GUARDS_EXIT0`**. Identity-checked selected application normal termination and actual exit confirmed, no forced kill or restoration inference.
- [x] Exact app relaunch/refresh, 5 November approximately 12:45: NSWorkspace finished launch, **AETHER PID 69118**, **Lab PID 69116** (`--m1-fixtures`), CG-owned Effect Disposable/Refuses Close titles verified, **`KINETIQ_RUNNING=false`**. Quick Look reset/cache reset, Finder Debug-directory update and clean `git diff --check` recorded.
- [ ] Review — engineering: remote CI results independently of local publication; Git commit/origin receipt tracked only in `TODO.md`.
- [ ] Review — user/engineering: explicitly grant Kinetiq's own AX/Recording, configure wave menu Enabled/Drag from Title Bar and Setup Close (nil is Off), observe disposable drag/close, indicators/focus/input and normal Stop/native restoration; no process-status acceptance shortcut.
- [ ] Review — engineering: arbitrary late/cancelled-launch/refused/timed-out quit timing remains source/manual contract, no injected SDK delay. Independent discovery/admission passed, not atomic mutual exclusion. Exclusions/motion, display/Spaces/full-screen/private-OS and displaced-window recovery remain open, as do full M2/M3/M4.

## M0 Bootstrap
- [x] Verify Package.swift and all targets build on the local Mac.
- [x] Add CI build/test workflow (remote execution pending).
- [x] Add structured logging categories.
- [x] Add app bootstrap lifecycle and dependency composition root (M1 native controls and M2 explicit preview connected).
- [x] Add configuration loading and default migration.

## M1 Window Intelligence
- [x] Enumerate on-screen and off-screen windows exposed by CG's normal-layer inventory.
- [x] Correlate CGWindow and AXUIElement conservatively; reject ambiguous mappings.
- [x] Probe frame attributes and position/size/main settable capability; inspect raise support.
- [x] Verify frame changes after requests with AX/CG convergence.
- [x] Track process launch identity/window generation and disappearance on refresh/control.
- [x] Test multiple windows per process using real external Test Lab fixtures.

Local gate evidence and remaining manual platform checks: `M1_VALIDATION.md`. Checked does not imply universal AX support or release certification.

## M2 Capture & Overlay
Checked build/publication evidence below belongs to **historical 1.0.7/build 8 or earlier**. Current 1.0.8 capture **22 functions / 26 cases**, two denial skips, and separate native **17/17** pass as recorded above; neither accepts full physical/platform gates or reuses historical metrics.

- [x] Implement SCStreamOutput callback path and validate the historical stream path with consented live Test Lab capture.
- [x] Convert stream sample buffers into immutable BGRA frame data on the capture owner queue.
- [x] Add bounded diagnostic async frame flow (30fps, stream queue depth 3, newest-only async buffering 1).
- [x] Implement stream lifecycle and error handling (single lease, start deadline 5s, independent cleanup deadline 3s).
- [x] Implement normal `preview(..., mode: .snapshot)` / Snapshot 5s using one `SCScreenshotManager.captureImage`, immutable BGRA up to 1600px per edge, no SCStream or screenshot refresh loop. Successful snapshot ownership is released before static presentation.
- [x] Share one mutually exclusive snapshot/stream lease per capture owner; bound screenshot waiting to 5s and independent cleanup to 3s without abandoning non-cancellable SDK callback ownership before actual completion. Preserve native/permission monitors during the intentionally static hold of at most 5s; freshness applies only before first presentation and `framesPresented == 1` means GPU completion, not scanout.
- [x] Historical 1.0.7 snapshot validation: default 34 functions / 39 cases executed, 26 skips (inventory 60/69), both app builds, focused move/minimize two cases, three full post-fix suites each 22 functions / 26 cases with two denial skips, separate native 14/14 with no skips. Not current 1.0.8 evidence. Fresh controlled Lab per full run; no concurrent native/capture mutations. See `M2_VALIDATION.md` for exact logs and timings.
- [x] Retain both full minimize failures, unsuccessful CG-only attempt and diagnostic; validate the combined 100ms exact CG ID/PID/on-screen check before AX plus next AX at 500ms after monitor start, avoiding immediate duplicate caller validation. Keep timeouts as failures, unchanged budgets and no SDK delay injection. Retain stale-handle test-only recovery correction to refresh the same ID/PID.
- [x] Historical 1.0.7 profile merge: preserve same-instrumentation default/capture-5/native profiles. Historical line coverage: snapshot lease 95.20%, stream lease 94.95%, capture coordinator 92.86%, preview 94.12%, Metal presenter 87.86%, total 84.49%; neither this nor pre-snapshot coverage is current 1.0.8 coverage.
- [x] Verify both rebuilt Info.plists as 1.0.7/build 8 and relaunch the exact local bundles (Test Lab PID 50953 with `--m1-fixtures`, AETHER PID 50955); complete Quick Look reset/cache refresh and Finder update.
- [x] Commit and push validated 1.0.7/build 8 to `origin/main`; owner: AETHER engineering. Remote CI is a separate review gate.
- [x] Exercise real target movement, minimization and closure after the first completed frame; remove overlay and reuse the same coordinator, with narrow already-stopped cleanup handling.
- [x] Exercise cancellation and Stop on an observed inactive startup lease, settle Start promptly and verify a fresh real frame through the same owner.
- [x] Verify single-lease ownership over three real concurrent Start/cancelled-or-normal Stop cycles, unique IDs, bounded stream termination and normal idempotent teardown.
- [x] Implement transparent overlay transaction for the selected display (not one panel per screen by default).
- [ ] Verify z-order, Spaces and full-screen behavior on physical displays.
- [ ] Manually verify physical scanout, intentionally static snapshot content and macOS indicator behavior. Live diagnostic is explicit continuous SCStream with expected OS recording indicators; Recording remains required for both modes, with no private flags, suppression, bypass or unconditional indicator-absence guarantee.
- [ ] Verify idempotent teardown and crash recovery under late callbacks and unexpected process termination.
- [ ] Complete SDK fault-order, broader manual/platform and macOS 14 runtime acceptance. M3/M4 development slice does not waive these checks.
- [x] Historical 1.0.7 snapshot/stream end-to-end consented proof (fresh first frame, removal, exclusions, cancellation and ownership/recovery); not current regression or all-platform certification. See `M2_VALIDATION.md` for retained evidence and the public-API-only reference comparison.

## Separate public-API diagnostic slice — automated local pass, manual acceptance pending
- [x] Implement `WindowEffectCoordinator` manual `.wobble` and `.dissolveClose`, one-shot capture/upload, privacy/cancellation/cleanup and system OR configuration Reduce Motion fade.
- [x] Implement independent 17 × 13 fixed-120Hz spring-lattice preview, UI duration 2s, original visible/interactive, interruption without native rollback; no global drag hook.
- [x] Implement hidden renderer preflight and original procedural dissolve (UI 1.1s) only after real public AX close and full CG inventory disappearance including off-screen windows (2s verification). Probe `canClose` with legacy Codable default false; no universal red-button/Cmd-W interception.
- [x] Retain one in-flight GPU submission and cached texture until removal, actual callback ownership beyond 750ms wait, maximum 3s animation and target-only 60fps pacing.
- [x] Implement confirmation/indicator guidance and Stop overlay/Escape/navigation; add reopenable Effect Disposable and real `windowShouldClose == false` refusal fixture.
- [x] Add test source and effect helper (`AETHER_RUN_EFFECT_INTEGRATION=1`, six functions / seven cases in source); native-close coverage uses existing `AETHER_RUN_WINDOW_INTEGRATION=1`.
- [x] Main-workflow final default/native/capture/effect results and five-profile compatible coverage verified above; diagnostic effects **6 functions / 7 cases**, zero skips. Effect coordinator **94.92%**, wobble **100%**, Metal **90.75%** line coverage, not physical/shader acceptance.
- [x] Verify both actual built Info.plists **1.0.8/build 9** and exact local app relaunches; Quick Look/Finder refresh and four active-engine helper guards also pass as recorded above. After final Swift validation, only separately syntax/integration-checked shell guards and documentation changed.
- [ ] User: record BEFORE/DURING/AFTER title/menu-bar indicators as visible / not visible / not determined; validate disposable-only manual Wobble/Close, Reduce Motion and cancellation. See `VISUAL_EFFECTS_VALIDATION.md`.
- [ ] Complete full M2, M3/M4 and Living Window acceptance independently; no slice result implies certification.

## M3 Motion
Full milestone tasks below remain open. The bounded monotonic manual-effect loop above is not a general timeline/keyframe engine; its cancellation/handoff implementation still needs final acceptance evidence.

- [ ] Implement monotonic timeline clock.
- [ ] Add keyframe interpolation.
- [ ] Bind animation tracks to render parameters.
- [ ] Implement cancellation and completion.
- [ ] Implement native/overlay handoff.

## M4 Physics
The preview-specific fixed-step lattice above remains an independent diagnostic, not the requested engine. Real external Kinetiq supplies its own model/input/shaders; final real drag/close integration proof, profiling and milestone acceptance remain pending. The general AETHER physics tasks below are not completed by launching that process.

- [ ] Fixed timestep accumulator.
- [ ] Spring solver stability tests.
- [ ] Mesh constraints.
- [ ] Wobbly effect.
- [ ] Input velocity sampling.
- [ ] Performance profiling.

## M5 Effects
- [ ] Implement each catalog effect.
- [ ] Add synthetic preview textures.
- [ ] Add parameter schema and validation.
- [ ] Add quality tiers and fallback.
- [ ] Add per-effect cancellation and cleanup tests.

## M6 Window Manager
- [ ] Layout tree and constraints.
- [ ] Binary split, grid, master/stack, columns, rows, Fibonacci, floating, custom.
- [ ] Snap zones and drag preview.
- [ ] Logical workspaces and groups.
- [ ] Shortcuts and rules.
- [ ] Reconcile AX operation failures.

## M7 Animation Studio
- [ ] Timeline UI.
- [ ] Keyframe editor.
- [ ] Curve editor.
- [ ] Effect composition.
- [ ] Preset validation/import/export.
- [ ] Undo/redo.

## M8 Intelligence & Dashboard
- [ ] Runtime diagnostics view models.
- [ ] Rules editor.
- [ ] Optional OpenAI-compatible provider.
- [ ] User-configured local endpoint.
- [ ] Explicit privacy boundary.

## M9 Release
- [ ] Stress/soak suite.
- [ ] Multi-display and sleep/wake.
- [ ] Permission revocation.
- [ ] VoiceOver and reduced-motion checks.
- [ ] Signing/notarization.
- [ ] Installer and update strategy.
