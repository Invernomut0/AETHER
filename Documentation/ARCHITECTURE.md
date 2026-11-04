# Architecture

## High-level layers

1. App/UI: SwiftUI dashboard, AppKit integration, menu bar and onboarding.
2. Orchestration: lifecycle, event bus, state store, scheduling and recovery.
3. Window intelligence: discovery, Accessibility control, geometry, displays.
4. Capture: ScreenCaptureKit sessions and frame processing.
5. Rendering: Metal device, render graph, textures, meshes, overlays.
6. Effects/animation/physics: composable effect graph, timeline and simulation.
7. Layouts: tiling tree, constraints, snapping, logical workspaces.
8. Persistence/intelligence: SQLite, presets, rules and optional LLM provider.

## Source of truth
Native window state is authoritative. Overlay state is transient and must never be treated as the actual application window.

## Dependency direction
Shared contracts are at the bottom. Feature modules depend on Shared and narrow abstractions. UI depends on orchestration-facing interfaces. Rendering must not depend on SwiftUI. Physics must not depend on AppKit. No circular dependencies.

## Concurrency
- AppKit and UI: MainActor.
- Window discovery/control: isolated adapters; AppKit calls on MainActor.
- Capture: dedicated actor/session owner.
- Rendering: serialized GPU submission and explicit resource ownership.
- Physics: deterministic fixed-step simulation.
- Persistence: database actor.
- Events: typed async streams or actor-isolated bus.

Do not send framework objects across actor boundaries unless the SDK explicitly supports it and the ownership contract is documented. Prefer immutable value snapshots and resource IDs.

## Window identity
A CGWindowID is a runtime identifier, not a durable persistent identity. Use a runtime WindowHandle containing process identity, native ID and generation. Reconcile after process/window lifecycle changes.

## Overlay transaction
1. Validate window and permissions.
2. Capture a fresh frame.
3. Prepare overlay and resources.
4. Present overlay.
5. Execute effect.
6. Remove overlay.
7. Reconcile native state.
8. Release resources.
9. Emit completion/failure.

Any failure after overlay presentation must execute cleanup and native-state reconciliation.

## Capture policy
Capture on demand, not continuously for all windows. Apply privacy exclusions. Do not capture protected/DRM content where the system prevents it. Keep queues bounded and drop stale frames rather than accumulating latency.

## Rendering policy
Use a render graph with optional passes. Keep a low-cost path for simple effects. Dynamic quality can reduce texture resolution, blur passes, mesh complexity and particle count under load.

## Workspace policy
AETHER logical workspaces are not native macOS Spaces. Native Space manipulation is not assumed to be available through public APIs.
