# Module Specifications

## AETHERShared
Pure value types, identifiers, errors, configuration and event contracts. No UI, capture or GPU ownership.

## AETHERCore
Application lifecycle, event routing, orchestration, permission state, recovery and operation scheduling.

## AETHERWindowManager
Window discovery via CoreGraphics; Accessibility capability probing and control; display topology; coordinate transforms. Correlate AX windows to CGWindowID using a verified strategy. Do not assume first AX window is the requested CG window.

## AETHERCapture
Own ScreenCaptureKit streams. Provide bounded frame delivery, cancellation, timeout, error state and privacy exclusions. Capture is on-demand.

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
