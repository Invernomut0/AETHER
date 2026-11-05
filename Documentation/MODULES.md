# Module Specifications

## AETHERShared
Pure value types, identifiers, errors, configuration and event contracts. No UI, capture or GPU ownership.

## AETHERCore
Application lifecycle, event routing, orchestration, permission state, recovery and operation scheduling. `WindowPreviewCoordinator.preview` defaults to `.snapshot`: one GPU-completed image retained statically for at most 5s with native/permission monitoring. `.live` is an explicit continuous diagnostic, not the default or M3 animation. Both check exact CG ID/PID/on-screen visibility every 100ms before AX; after caller validation following capture/before presentation, the next monitor AX check starts at 500ms, not as an immediate duplicate racing native minimization. Generation/geometry checks and timeout budgets remain intact. Focused move/minimize and three complete post-fix suites passed locally; full platform/M3 acceptance remains pending. See `API_CONTRACTS.md` and `M2_VALIDATION.md`.

## AETHERWindowManager
Window discovery via CoreGraphics; Accessibility capability probing and control; display topology; coordinate transforms. Correlate AX windows to CGWindowID using a verified strategy. Do not assume first AX window is the requested CG window.

## AETHERCapture
Own on-demand ScreenCaptureKit screenshots and diagnostic streams under one mutually exclusive lease. Normal capture uses one `SCScreenshotManager.captureImage`, no `SCStream` or refresh loop; handoff is immutable BGRA data, at most 1600px per edge. Screenshot waiting (5s) and independent cleanup (3s) bound Swift waits, not non-cancellable SDK callbacks; retain ownership until actual completion. Release successful snapshot ownership before static Metal presentation. Live diagnostics retain bounded 30fps stream delivery. Both enforce consent and privacy exclusions; neither suppresses OS indicators or guarantees their absence. Final local suites passed; final merged line coverage is snapshot lease 95.20%, stream lease 94.95% and capture coordinator 92.86% (historical pre-snapshot metrics are separate). See `Sources/AETHERCapture/README.md` for lifecycle details.

## AETHERRendering
Own MTLDevice, command queues, pipelines, texture pools and render graph. No AppKit view logic in shader code. Provide diagnostics and quality adaptation.

## AETHEREffects
Effect descriptors, registry, parameter validation and composition. Built-in catalog must not be considered implemented merely because a descriptor exists.

## AETHERPhysics
Fixed-step simulation, spring solver, damping, constraints and particle simulation. Pure deterministic core where possible.

## AETHERAnimation
Timeline evaluation, keyframes, interpolation, scheduling, cancellation and effect-to-render bindings.

## AETHERLayouts
Tree-based tiling, layout validation, constraints, snapping and logical workspace model.

## AETHERPersistence
Versioned config, preset import/export, transactional writes and migrations. SQLite is the planned release store; current JSON repositories are bootstrap implementations.

## AETHERIntelligence
Rule evaluation and optional LLM command interpretation. No captured pixels or sensitive window titles sent to external providers.

## AETHERInterface
Dashboard, effect browser, editor, settings, diagnostics and onboarding. View models consume service protocols, not concrete system APIs.
