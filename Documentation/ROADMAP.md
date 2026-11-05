# Roadmap and milestone gates

Durations are indicative estimates for one developer with coding-agent assistance, not guarantees.

Local progress: 1.0.7 (build 8) passed local validation. M0/M1 and the current local M2 snapshot/stream-overlay proof passed, including startup Stop/concurrent ownership recovery without dropping unconfirmed SDK ownership. The normal preview defaults to one-shot **Snapshot 5s**; explicit **Live diagnostic** retains continuous 30fps SCStream with expected OS recording indicators. Final default validation passed 34 functions / 39 cases with 26 skips (inventory 60/69), both app builds passed, three full post-fix capture suites each passed 22 functions / 26 cases with two denial skips, and separate native regression passed 14/14 with no skips. Final compatible merged line coverage is 84.49% total; historical pre-snapshot metrics remain historical. Both rebuilt apps were launched with verified 1.0.7/build 8 Info.plists; Quick Look/Finder refresh completed. See `M2_VALIDATION.md` for exact logs, failed minimize/CG-only attempts, final monitor scheduling fix and local relaunch evidence. Remote CI review is separate and pending. Full M2 acceptance still needs physical display/OS-indicator and scanout checks, manual recovery, SDK callback/fault orders and macOS 14 runtime evidence. M3 has not started; its animation proof is subsequently needed for Living Window Gate 0.

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

Current Gate 0 status:
- Implementation exists for one-shot snapshots, bounded diagnostic streams, preview orchestration and overlay teardown. Snapshot ownership is released before static Metal presentation; the texture intentionally stays unchanged for at most 5s under native/permission monitoring, not a refresh loop or animation.
- Current explicit-consent snapshot/stream-overlay proof passed locally in three full post-fix suites; both rebuilt 1.0.7/build 8 apps were launched. The Living Window animation proof remains pending M3.
- Physical multi-display Spaces/full-screen behavior and crash/recovery evidence are still pending manual validation.

Screen Recording remains required for both modes. One-shot public APIs do not guarantee absent macOS indicators; no private flags, suppression or permission bypass is adopted. The pinned Wobbly comparison in `M2_VALIDATION.md` is public-API design only, not GPL source reuse, launch warmup or off-screen native-window parking.

## Parallelizable work
- Shared models, documentation, persistence schema and Test Lab can proceed alongside M1.
- Effect shader prototypes can be developed against synthetic textures before native capture is complete.
- Layout engine can be developed against mocked window descriptors, then integrated with the real controller.

## Release gate
No release if an overlay can remain orphaned, if permission denial breaks the app, if native window state is not reconciled, or if core functionality depends on undocumented/private APIs.

No M3 progression while the M2 capture/overlay exit gate remains pending. Completing the broader Living Window Gate 0 also requires M3's animation proof; neither gate implies release certification.
