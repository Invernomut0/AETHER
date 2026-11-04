# Milestone Task Breakdown

## M0 Bootstrap
- [x] Verify Package.swift and all targets build on the local Mac.
- [x] Add CI build/test workflow (remote execution pending).
- [x] Add structured logging categories.
- [x] Add app bootstrap lifecycle and dependency composition root (M1 connected; M2 remains disconnected).
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
- [ ] Implement SCStreamOutput.
- [ ] Convert CMSampleBuffer pixel buffers into GPU textures safely.
- [ ] Add bounded async frame channel.
- [ ] Implement stream lifecycle and error handling.
- [ ] Implement transparent per-display overlay.
- [ ] Verify z-order, Spaces and full-screen behavior.
- [ ] Implement idempotent teardown and crash recovery.

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
