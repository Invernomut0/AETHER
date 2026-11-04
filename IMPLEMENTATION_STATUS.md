# Implementation Status

This repository intentionally distinguishes foundations from production-complete capabilities.

## Local milestone baseline — 2026-11-04

Version 1.0.3 (build 4) adds the M1 native window-control slice to M0. Local Swift package tests and both Xcode app builds have passed on Apple Silicon with Xcode 27.2 / Swift 6.4.2 after installing the official Metal Toolchain. Fourteen native tests pass with real external Test Lab fixtures and user-granted Accessibility. CI is configured; remote run status must be checked on GitHub independently. Deployment target 14.0 is a compile target, not a claim of runtime certification on macOS 14.

Configuration is loaded/migrated before readiness. Startup inspects permissions without prompting; prompts require an explicit button press. The Windows panel connects discovery and verified native control; uncorrelated windows remain read-only. No first-window fallback exists. M2 capture/overlay remains incomplete and never starts implicitly. See `Documentation/M1_VALIDATION.md` for the local gate and manual review boundary.

| Area | Status in this archive |
|---|---|
| Shared IDs and core models | Foundation implemented |
| Basic event bus | Foundation implemented |
| Core coordinator | M0 configuration bootstrap, cancellation/invalidation, lifecycle logging |
| CoreGraphics discovery | Normal-layer on/off-screen inventory, app/display metadata and conservative AX correlation |
| Accessibility window control | Actor-owned registry/generations, per-attribute capabilities, selected-window focus, bounded geometry verification |
| ScreenCaptureKit | API discovery/configuration scaffold; output pipeline not implemented |
| Metal device | Device discovery foundation |
| Metal renderer | Lifecycle/diagnostics foundation; render graph and overlay not implemented |
| Shader files | Starter shader examples; not a complete pipeline |
| Effect registry | Foundation implemented |
| Effects catalog | Descriptors only; visual effects require implementation |
| Physics | Basic spring solver and world foundation |
| Animation | Scheduler foundation; timeline execution incomplete |
| Layouts | Basic split/leaf tree foundation |
| Persistence | JSON bootstrap and schema 0→1 migration tested; SQLite required for release |
| Intelligence | Rule model foundation; LLM disabled by default |
| Dashboard | Live bootstrap/schema/permissions and Windows panel; other navigation remains scaffold |
| Test Lab | Real resizable/fixed-size/equal-overlap fixtures, retained windows and close cleanup |
| Automated tests | Original/configuration/lifecycle suites plus desktop discovery and opt-in live multiwindow control |

AETHER 1.0 is not release-ready until all milestone tasks and acceptance criteria are completed on macOS.
