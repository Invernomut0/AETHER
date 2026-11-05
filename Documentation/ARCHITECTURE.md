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

## Explicit experimental engine contract — 5 November 2026

The requested desktop-effects engine is the **real external Kinetiq.app**, not AETHER's independent manual spring-lattice/dissolve preview. `AETHERCore/KinetiqEngineCoordinator` manages explicit launch/connect and normal quit; `AETHERInterface/KinetiqEnginePanel` is the Effects-page control surface. Kinetiq owns its physics, shaders, global input integration and capture in a separate process. No Kinetiq source/assets are linked or copied into AETHER, and there is no effect-control/readiness IPC.

The updated user contract authorizes **private AX mapping, event-tap/click replay and temporary off-screen native-window parking** in this optional experimental path. It remains disabled by default in AETHER, permission-gated and risk-labelled; the public-API Windows diagnostics remain available without Kinetiq after it exits. ADR 0002's public stable baseline remains in force. This authorization is not full M2/M3/M4 acceptance or release certification.

RuntimeModel admission blocks AETHER focus/move/capture/effects for active/pending/unresolved engines, including independent instances; passive discovery is allowed. It rechecks after configuration await; visible panels observe status every **500ms**, without autostart. Final **7/7 XCTest** includes actual RuntimeModel six command rejections, passive refresh and unchanged fixture geometry/visibility. `@testable AETHERInterface` is a **CoreTests-only dependency**, not production Core (no cycle). This is **not a cross-process IPC lock**: an independent external start during already-in-flight AETHER work is not atomically prevented. Finish/cancel operations/overlays before any external launch; do not infer unconditional mutual exclusion. Late/refused-quit timing and visual readiness remain manual/source-contract review. See `KINETIQ_ENGINE.md` and `VISUAL_EFFECTS_VALIDATION.md` for exact receipts/limits.

## Source of truth
Native window state is authoritative. Overlay state is transient and must never be treated as the actual application window.

Experimental Kinetiq may temporarily move a real native window off-screen while presenting its captured representation. This is authorized native-state mutation, not closure or transfer of authority to an overlay. Restoring/reconciling native state on normal termination is the intended target; failed AX operations or crashes can leave windows displaced. Process exit is not restoration proof, and AETHER cannot promise crash recovery for the external engine.

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
For AETHER-owned capture, capture on demand, not continuously for all windows. Apply privacy exclusions. Do not capture protected/DRM content where the system prevents it. Keep queues bounded and drop stale frames rather than accumulating latency.

External Kinetiq uses its own `captureSampleBuffer` path, including prefetch/recapture on raise, not exactly one image per gesture. AETHER limits, deadlines, denylist and Reduce Motion are not inherited. Kinetiq needs its own user-granted AX/Recording; AETHER bootstrap, selection and status refresh stay passive. Explicit **Kinetiq Start / Connect** launches/connects and may show its own prompts; no automatic grants. Never bypass indicators or claim they are absent.

## Rendering policy
Use a render graph with optional passes. Keep a low-cost path for simple effects. Dynamic quality can reduce texture resolution, blur passes, mesh complexity and particle count under load.

## Workspace policy
AETHER logical workspaces are not native macOS Spaces. Native Space manipulation is not assumed to be available through public APIs.
