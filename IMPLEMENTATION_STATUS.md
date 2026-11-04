# Implementation Status

This repository intentionally distinguishes foundations from production-complete capabilities.

## Local milestone baseline — 2026-11-04

Version 1.0.4 (build 5) keeps M0/M1 locally accepted and adds a first M2 capture/overlay implementation slice. Local Swift package tests and both Xcode app builds were previously passing on Apple Silicon with Xcode 27.2 / Swift 6.4.2 after installing the official Metal Toolchain. M1 acceptance evidence remains the previously confirmed live fixture run with user-granted Accessibility. CI is configured; remote run status must be checked on GitHub independently. Deployment target 14.0 is a compile target, not a claim of runtime certification on macOS 14.

Configuration is loaded/migrated before readiness. Startup inspects permissions without prompting; prompts require an explicit button press. The Windows panel connects discovery and verified native control; uncorrelated windows remain read-only. No first-window fallback exists.

M2 status is **implementation in progress, capture/overlay exit gate not accepted**. The latest host used for testing reported `AX=true` and `Recording=false`; no live ScreenCaptureKit output-path validation was completed under granted Screen Recording consent. The wider Living Window Gate 0 also requires M3 animation. See `Documentation/M2_VALIDATION.md` for implementation evidence and pending checks.

| Area | Status in this archive |
|---|---|
| Shared IDs and core models | Foundation implemented |
| Basic event bus | Foundation implemented |
| Core coordinator | M0 configuration bootstrap, cancellation/invalidation, lifecycle logging |
| CoreGraphics discovery | Normal-layer on/off-screen inventory, app/display metadata and conservative AX correlation |
| Accessibility window control | Actor-owned registry/generations, per-attribute capabilities, selected-window focus, bounded geometry verification |
| ScreenCaptureKit | First output pipeline implementation: serial callback ownership, immutable BGRA frame copy, bounded preview flow; live consent-host runtime validation still pending |
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
| Test Lab | Real resizable/fixed-size/equal-overlap fixtures, retained windows and close cleanup |
| Automated tests | Default validation passed: 33 functions / 38 expanded cases executed, 17 skipped; earlier 14-test M1 opt-in passed, final interactive rerun blocked by locked desktop/secure input; live capture untested |

AETHER 1.0 is not release-ready until all milestone tasks and acceptance criteria are completed on macOS, including consented M2 capture evidence and the broader Living Window Gate 0 animation proof.
