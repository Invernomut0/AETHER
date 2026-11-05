# Roadmap and milestone gates

Durations are indicative estimates for one developer with coding-agent assistance, not guarantees.

Current development: **1.0.8/build 9 locally validated**. The updated **5 November 2026** contract requests real external **Kinetiq.app**, authorizing optional private AX mapping/event-tap/click replay/off-screen parking. Its consented panel is distinct from independent diagnostic **Wobble 2s / Close with dissolve…**. Helper/build, actual RuntimeModel admission/lifecycle tests, default/live regressions, compatible coverage and both built versions are verified, as are all four active-engine exit-2 guards, identity-checked normal engine exit, exact local app relaunches and Quick Look/Finder refresh. Default validation passes **53 functions / 58 cases**, with **34 skipped functions**; upstream tests pass **74/74**. Git commit/origin verification is a publication receipt tracked in `TODO.md`, not a milestone/readiness gate; remote CI remains separate Review. See `KINETIQ_ENGINE.md` and `VISUAL_EFFECTS_VALIDATION.md`.

M0/M1 remain locally accepted. Current capture **22 functions / 26 cases**, two denial skips; native **17/17**, effects **6 functions / 7 cases**, lifecycle/admission **7/7** pass locally. Historical 1.0.7/build 8 results stay in `M2_VALIDATION.md`, not reused as current evidence. **Full M2 physical/platform gate remains NOT accepted**: indicators/scanout, recovery, SDK fault orders and macOS 14 runtime stay open. Local tests do not accept full M3/M4, Living Window or release gates.

| Milestone | Focus | Estimate | Exit gate |
|---|---|---:|---|
| M0 | Project bootstrap, CI, logging, dependency graph | 1 week | Clean build and tests |
| M1 | Window discovery, Accessibility, geometry | 2 weeks | Test Lab windows discovered and controllable where supported |
| M2 | ScreenCaptureKit and overlay | 2 weeks | Fresh frame presented and reliably removed |
| M3 | Motion engine and basic transitions; bounded manual slice in development only | 2 weeks | Repeatable transitions with cancellation; full gate pending |
| M4 | Physics and Wobbly; real external Kinetiq experiment plus separate diagnostic lattice | 3 weeks | Observed real drag/close, cleanup/input and platform evidence; full gate pending |
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
- Implementation exists for one-shot snapshots, bounded diagnostic streams, preview orchestration and overlay teardown. Snapshot ownership is released before static Metal presentation; Snapshot 5s retains an unchanged texture, not an animation or refresh loop.
- Current 1.0.8 real-fixture diagnostic effects pass **6 functions / 7 cases**, zero skips; Wobble preserves the native window and Close dissolves only after verified disappearance. Historical launches remain historical. Automated behavior is not physical animation/indicator/input acceptance or accepted Living Window proof.
- Physical multi-display Spaces/full-screen behavior and crash/recovery evidence are still pending manual validation.

Screen Recording remains required for AETHER capture and for Kinetiq under its own permission identity. Indicators remain user-pending, never suppressed or guaranteed absent. `/Users/lorenzov/dev/Wobbly` is now the actual **external Kinetiq** engine checkout: its private mapping, input replay and parking are explicitly authorized only in that opted-in process. No Kinetiq code/assets are copied into AETHER; preserve upstream GPL/NOTICE and CC-BY texture notices. Process separation is not a licensing exemption or general GPL incompatibility claim. Its raise-time prefetch/recapture, exclusions, physics and motion settings are not governed by AETHER's snapshot policy.

The bridge has no readiness/settings IPC; PID existence is not drag/close proof. Actual RuntimeModel admission rejects six mutating/capture/effect commands for active/pending engines, permits refresh and rechecks after configuration await; visible panels observe every 500ms. **Not a cross-process IPC lock**: an independent start during in-flight work is not atomically prevented. Finish/cancel AETHER work first, save work/use disposables. Normal quit attempts restoration, but crashes/AX failures may displace windows; exit alone never accepts recovery.

## Parallelizable work
- Shared models, documentation, persistence schema and Test Lab can proceed alongside M1.
- Effect shader prototypes can be developed against synthetic textures before native capture is complete.
- Layout engine can be developed against mocked window descriptors, then integrated with the real controller.

## Release gate
No release if an overlay can remain orphaned, if permission denial breaks the app, if native window state is not reconciled, or if core functionality depends on undocumented/private APIs.

The user's updated 5 November request permits the **optional external Kinetiq experiment as well as the separate bounded diagnostic slice** while full M2 acceptance remains pending; it does not waive physical/platform checks. Kinetiq stays disabled by default in AETHER and no stable release depends on its private techniques. General milestone progression/catalog expansion still require relevant gates. Living Window Gate 0 requires observed animation, native-state/focus/input and cleanup evidence; neither implementation, process launch nor local tests alone imply release certification.
