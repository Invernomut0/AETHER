# Implementation Status

This repository intentionally distinguishes foundations from production-complete capabilities.

## Local milestone baseline — 2026-11-04

Version 1.0.2 (build 3) retains the M0 bootstrap slice introduced in 1.0.1. Local Swift package build/tests and both Xcode app builds have passed on Apple Silicon with Xcode 27.2 / Swift 6.4.2 after installing the official Metal Toolchain. CI is configured; remote run status must be checked on GitHub independently. Deployment target 14.0 is a compile target, not a claim of runtime certification on macOS 14.

Configuration is loaded/migrated before readiness. Startup inspects permissions without prompting; prompts require an explicit button press. M1 window control and M2 capture/overlay are not exposed as complete. The unsafe first-window AX controller remains a known M1 blocker and is not connected to the UI.

| Area | Status in this archive |
|---|---|
| Shared IDs and core models | Foundation implemented |
| Basic event bus | Foundation implemented |
| Core coordinator | M0 configuration bootstrap, cancellation/invalidation, lifecycle logging |
| CoreGraphics discovery | Basic discovery foundation; AX correlation incomplete |
| Accessibility window control | Experimental foundation; robust target correlation required |
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
| Dashboard | Live bootstrap/schema/permission diagnostics; remaining navigation scaffold |
| Test Lab | Basic fixture app scaffold |
| Automated tests | Original unit tests plus real-filesystem configuration/lifecycle tests |

AETHER 1.0 is not release-ready until all milestone tasks and acceptance criteria are completed on macOS.
