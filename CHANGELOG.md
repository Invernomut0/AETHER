# Changelog

## 1.0.3 — M1 native window intelligence (2026-11-04)
- Replace first-AX-window control with mutually unique public-API correlation and session-scoped generations.
- Enumerate normal-layer CG windows, enrich live application/display metadata, probe AX capabilities and invalidate disappeared or ambiguous targets.
- Isolate AX references and bounded IPC in a dedicated actor; verify selected-window focus and geometry through actual readback.
- Handle WindowServer publication lag and AppKit resize clamping by positioning before growth and checking AX/CG convergence.
- Add the Windows dashboard panel with explicit refresh, capability-gated Focus/Center/Left half controls and structured task cancellation.
- Add real multiwindow Test Lab fixtures and opt-in native integration tests; Screen Recording is not required for native control.
- Increment app version to 1.0.3 (build 4). M2 capture/overlay, multi-display certification and release hardening remain pending.

## 1.0.2 — Repository publication (2026-11-04)
- Configure the owner-provided GitHub origin and document the main branch publication workflow.
- Increment app version to 1.0.2 (build 3); M0 behavior and M1/M2 limitations are unchanged.

## 1.0.1 — M0 bootstrap (2026-11-04)
- Validate on macOS with Xcode 27.2 / Swift 6.4.2 and the official Metal Toolchain.
- Fix display syntax, missing cross-module model initializers, permission isolation and SwiftUI app entry-point builds.
- Add persistent configuration bootstrap, schema 0 migration, unsupported-schema protection and cancellation-aware lifecycle.
- Connect startup and passive permission diagnostics to the dashboard; prompts remain explicit user actions.
- Add unified logging, filesystem-backed configuration/lifecycle tests, coverage-enabled CI and shared app schemes.
- Add repeatable local application builds; native control and Living Window remain gated by M1 and M2.
- Keep Wobbly as an architectural reference only; no GPL source was copied.

## 1.0.0-foundation
- Initial AETHER repository scaffold.
- Modular Swift Package structure.
- Shared models and protocol contracts.
- Initial SwiftUI dashboard.
- Metal shader starter library.
- Documentation, Copilot instructions and test plan.
