# Milestone Task Breakdown

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
- [x] Implement SCStreamOutput callback path and validate the historical stream path with consented live Test Lab capture.
- [x] Convert stream sample buffers into immutable BGRA frame data on the capture owner queue.
- [x] Add bounded diagnostic async frame flow (30fps, stream queue depth 3, newest-only async buffering 1).
- [x] Implement stream lifecycle and error handling (single lease, start deadline 5s, independent cleanup deadline 3s).
- [x] Implement normal `preview(..., mode: .snapshot)` / Snapshot 5s using one `SCScreenshotManager.captureImage`, immutable BGRA up to 1600px per edge, no SCStream or screenshot refresh loop. Successful snapshot ownership is released before static presentation.
- [x] Share one mutually exclusive snapshot/stream lease; bound screenshot waiting to 5s and independent cleanup to 3s without abandoning non-cancellable SDK callback ownership before actual completion. Preserve native/permission monitors during the intentionally static hold of at most 5s; freshness applies only before first presentation and `framesPresented == 1` means GPU completion, not scanout.
- [x] Finish current local snapshot validation: default 34 functions / 39 cases executed, 26 skips (inventory 60/69), both app builds, focused move/minimize two cases, three full post-fix suites each 22 functions / 26 cases with two denial skips, separate native 14/14 with no skips. Fresh controlled Lab per full run; no concurrent native/capture mutations. See `M2_VALIDATION.md` for exact logs and timings.
- [x] Retain both full minimize failures, unsuccessful CG-only attempt and diagnostic; validate the combined 100ms exact CG ID/PID/on-screen check before AX plus next AX at 500ms after monitor start, avoiding immediate duplicate caller validation. Keep timeouts as failures, unchanged budgets and no SDK delay injection. Retain stale-handle test-only recovery correction to refresh the same ID/PID.
- [x] Preserve/explicitly merge fresh same-instrumentation default/capture-5/native profiles. Final line coverage: snapshot lease 95.20%, stream lease 94.95%, capture coordinator 92.86%, preview 94.12%, Metal presenter 87.86%, total 84.49%; pre-snapshot metrics remain historical.
- [x] Verify both rebuilt Info.plists as 1.0.7/build 8 and relaunch the exact local bundles (Test Lab PID 50953 with `--m1-fixtures`, AETHER PID 50955); complete Quick Look reset/cache refresh and Finder update.
- [x] Commit and push validated 1.0.7/build 8 to `origin/main`; owner: AETHER engineering. Remote CI is a separate review gate.
- [x] Exercise real target movement, minimization and closure after the first completed frame; remove overlay and reuse the same coordinator, with narrow already-stopped cleanup handling.
- [x] Exercise cancellation and Stop on an observed inactive startup lease, settle Start promptly and verify a fresh real frame through the same owner.
- [x] Verify single-lease ownership over three real concurrent Start/cancelled-or-normal Stop cycles, unique IDs, bounded stream termination and normal idempotent teardown.
- [x] Implement transparent overlay transaction for the selected display (not one panel per screen by default).
- [ ] Verify z-order, Spaces and full-screen behavior on physical displays.
- [ ] Manually verify physical scanout, intentionally static snapshot content and macOS indicator behavior. Live diagnostic is explicit continuous SCStream with expected OS recording indicators; Recording remains required for both modes, with no private flags, suppression, bypass or unconditional indicator-absence guarantee.
- [ ] Verify idempotent teardown and crash recovery under late callbacks and unexpected process termination.
- [ ] Complete SDK fault-order, broader manual/platform and macOS 14 runtime acceptance; M3 has not started.
- [x] Validate current snapshot/stream output end-to-end with explicit Screen Recording consent (fresh first frame, removal, exclusions, cancellation and ownership/recovery); local passes do not certify all platform/fault paths. See `M2_VALIDATION.md` for retained evidence and the pinned public-API-only Wobbly comparison (no GPL copying, launch warmup or off-screen parking adoption).

## M3 Motion
- [ ] Implement monotonic timeline clock.
- [ ] Add keyframe interpolation.
- [ ] Bind animation tracks to render parameters.
- [ ] Implement cancellation and completion.
- [ ] Implement native/overlay handoff.

## M4 Physics
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
