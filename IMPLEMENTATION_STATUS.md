# Implementation Status

This repository intentionally distinguishes foundations from production-complete capabilities.

## Local milestone baseline — 2026-11-04

Version 1.0.6 (build 7) adds real M2 target interruption/recovery tests and fixes already-stopped capture cleanup after target closure. The initial capture/overlay implementation was introduced in 1.0.4 and consented live evidence published in 1.0.5. M0/M1 remain locally accepted. Validation uses Apple Silicon with Xcode 27.2 / Swift 6.4.2 and the official Metal Toolchain. CI is configured; remote run status must be checked on GitHub independently. Deployment target 14.0 is a compile target, not a claim of runtime certification on macOS 14.

Configuration is loaded/migrated before readiness. Startup inspects permissions without prompting; prompts require an explicit button press. The Windows panel connects discovery and verified native control; uncorrelated windows remain read-only. No first-window fallback exists.

M2 status is **local capture/overlay proof passed; full platform acceptance pending**. The latest host reported `AX=true`, `Recording=true` and secure input disabled. Three consecutive unchanged capture suites passed after an initial focus assertion observed macOS UserNotificationCenter becoming frontmost. All three live capture tests passed; the two denial tests were correctly inapplicable with Recording granted. M3 has not started; the wider Living Window Gate 0 still requires animation. See `Documentation/M2_VALIDATION.md` for evidence and outstanding manual checks.

| Area | Status in this archive |
|---|---|
| Shared IDs and core models | Foundation implemented |
| Basic event bus | Foundation implemented |
| Core coordinator | M0 configuration bootstrap, cancellation/invalidation, lifecycle logging |
| CoreGraphics discovery | Normal-layer on/off-screen inventory, app/display metadata and conservative AX correlation |
| Accessibility window control | Actor-owned registry/generations, per-attribute capabilities, selected-window focus, bounded geometry verification |
| ScreenCaptureKit | Serial callback ownership, immutable BGRA frame copy and bounded preview flow; live capture, exclusion, cancellation and move/minimize/close with same-coordinator recovery passed with explicit consent |
| Metal device | Device discovery foundation |
| Metal renderer | Overlay presentation transaction implemented for preview; diagnostics remain partial (estimated texture bytes, GPU-completion counter) |
| Shader files | Starter shader examples; not a complete pipeline |
| Effect registry | Foundation implemented |
| Effects catalog | Descriptors only; visual effects require implementation |
| Physics | Basic spring solver and world foundation |
| Animation | Scheduler foundation; timeline execution incomplete |
| Layouts | Basic split/leaf tree foundation |
| Persistence | JSON bootstrap and schema 0→1 migration tested; SQLite required for release |
| Intelligence | Rule model foundation; LLM disabled by default |
| Dashboard | Live bootstrap/schema/permissions and Windows panel; explicit 5-second preview controls integrated; other navigation remains scaffold |
| Test Lab | Real resizable/fixed-size/equal-overlap fixtures, independent M2 disposable, retained windows and close cleanup |
| Automated tests | 1.0.6 default validation and both app builds passed: 34 functions / 39 cases executed, 17 skips. Four post-fix capture suites each execute 13 functions / 15 cases with 2 denial skips; separate native regression 14/14. Final line coverage: capture lease 93.56%, preview 93.39%. Failed attempts retained in M2 validation report |

AETHER 1.0 is not release-ready until all milestone tasks and acceptance criteria are completed on macOS, including consented M2 capture evidence and the broader Living Window Gate 0 animation proof.
