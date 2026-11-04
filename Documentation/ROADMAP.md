# Roadmap and milestone gates

Durations are indicative estimates for one developer with coding-agent assistance, not guarantees.

Local progress (1.0.3): M0 and the conservative M1 Test Lab gate have passed. M2 is next; Living Window remains unproven until capture, overlay and reliable teardown are integrated. See `M1_VALIDATION.md` for evidence and platform review limitations.

| Milestone | Focus | Estimate | Exit gate |
|---|---|---:|---|
| M0 | Project bootstrap, CI, logging, dependency graph | 1 week | Clean build and tests |
| M1 | Window discovery, Accessibility, geometry | 2 weeks | Test Lab windows discovered and controllable where supported |
| M2 | ScreenCaptureKit and overlay | 2 weeks | Fresh frame presented and reliably removed |
| M3 | Motion engine and basic transitions | 2 weeks | Repeatable transitions with cancellation |
| M4 | Physics and Wobbly | 3 weeks | Stable fixed-step simulation |
| M5 | Advanced effects | 4 weeks | Effects registered, configurable and tested |
| M6 | Layouts and logical workspaces | 3 weeks | Layouts respect constraints and recover |
| M7 | Animation Studio | 3 weeks | Preset authoring, timeline and serialization |
| M8 | Intelligence and diagnostics | 2 weeks | Rules, optional LLM, runtime dashboard |
| M9 | Hardening and release | 3 weeks | Acceptance suite, signing and notarization |

## Gate 0 — Living Window
This is the highest-risk technical proof:
- Discover a controlled Test Lab window.
- Read geometry through Accessibility when granted.
- Capture through ScreenCaptureKit.
- Present a temporary Metal overlay.
- Animate a captured representation.
- Remove overlay and reconcile original.
- Verify focus, visibility and input.

Do not scale up the effect catalog until this gate is reliable.

## Parallelizable work
- Shared models, documentation, persistence schema and Test Lab can proceed alongside M1.
- Effect shader prototypes can be developed against synthetic textures before native capture is complete.
- Layout engine can be developed against mocked window descriptors, then integrated with the real controller.

## Release gate
No release if an overlay can remain orphaned, if permission denial breaks the app, if native window state is not reconciled, or if core functionality depends on undocumented/private APIs.
