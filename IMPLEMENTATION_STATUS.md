# Implementation Status

This repository intentionally distinguishes foundations from production-complete capabilities.

## Local milestone baseline — 2026-11-05

Version 1.0.7 (build 8) includes the startup Stop waiter fix, concurrent ownership tests and the normal one-shot snapshot path. Version 1.0.6 added target interruption/recovery and narrow already-stopped cleanup handling. The initial capture/overlay implementation was introduced in 1.0.4 and consented live evidence published in 1.0.5. M0/M1 remain locally accepted. Recorded validation uses Apple Silicon with Xcode 27.2 / Swift 6.4.2 and the official Metal Toolchain; 1.0.7 passed local validation and both app builds. Both built Info.plists were verified as 1.0.7/build 8; the rebuilt apps were launched and Quick Look/Finder refresh completed. CI status must be checked independently. Deployment target 14.0 is not runtime certification on macOS 14.

Configuration is loaded/migrated before readiness. Startup inspects permissions without prompting; prompts require an explicit button press. The Windows panel connects discovery and verified native control; uncorrelated windows remain read-only. No first-window fallback exists.

M2 status is **current local snapshot/stream-overlay proof passed; full platform acceptance pending**. Three complete post-fix capture suites passed with pre-granted AX/Recording and secure input off, fresh controlled Lab fixtures per full run and no concurrent native/capture mutations. Two full snapshot minimize failures and a failed CG-only attempt remain retained: the fix combines exact CG ID/PID/on-screen monitoring every 100ms before AX with the next AX check at 500ms after monitor start, avoiding an immediate duplicate of caller validation after capture/before presentation. Timeouts remain failures; budgets and assertions were not relaxed and no SDK delay was injected. Retained failures, exact results and verified build/relaunch evidence are in `Documentation/M2_VALIDATION.md`. M3 has not started; Living Window Gate 0 still requires animation, with physical display/OS-indicator, SDK fault, manual recovery and macOS 14 runtime checks pending.

| Area | Status in this archive |
|---|---|
| Shared IDs and core models | Foundation implemented |
| Basic event bus | Foundation implemented |
| Core coordinator | M0 configuration bootstrap, cancellation/invalidation, lifecycle logging |
| CoreGraphics discovery | Normal-layer on/off-screen inventory, app/display metadata and conservative AX correlation |
| Accessibility window control | Actor-owned registry/generations, per-attribute capabilities, selected-window focus, bounded geometry verification |
| ScreenCaptureKit | Normal one-shot `captureImage` snapshot (no SCStream/refresh loop), immutable BGRA up to 1600px per edge; one mutually exclusive snapshot/stream lease. Screenshot wait 5s, independent cleanup 3s; non-cancellable SDK callbacks retain ownership until actual completion. Final local snapshot/stream suites passed; historical failures retained |
| Metal device | Device discovery foundation |
| Metal renderer | Snapshot lease released before static presentation; freshness checked only at first presentation, texture intentionally retained statically for at most 5s with native/permission monitoring. Successful snapshot `framesPresented == 1` is GPU completion, not scanout; texture bytes are estimated |
| Shader files | Starter shader examples; not a complete pipeline |
| Effect registry | Foundation implemented |
| Effects catalog | Descriptors only; visual effects require implementation |
| Physics | Basic spring solver and world foundation |
| Animation | Scheduler foundation; timeline execution incomplete |
| Layouts | Basic split/leaf tree foundation |
| Persistence | JSON bootstrap and schema 0→1 migration tested; SQLite required for release |
| Intelligence | Rule model foundation; LLM disabled by default |
| Dashboard | Live bootstrap/schema/permissions and Windows panel; default Snapshot 5s versus explicit Live diagnostic (continuous 30fps SCStream, OS recording indicators expected); other navigation remains scaffold |
| Test Lab | Real resizable/fixed-size/equal-overlap fixtures, independent M2 disposable, retained windows and close cleanup |
| Automated tests | Inventory 60 functions / 69 cases; final default passed 34 functions / 39 cases, 26 skips. Three full post-fix capture suites each passed 22 functions / 26 cases with 2 denial skips (inventory 24/28); separate native passed 14/14, zero skips. Final compatible merged line coverage: snapshot lease 95.20%, stream lease 94.95%, capture coordinator 92.86%, preview 94.12%, Metal presenter 87.86%, total 84.49%; pre-snapshot metrics remain historical |

Both preview modes require Screen Recording; neither uses private flags, indicator suppression or bypass, and no absence-of-macOS-indicators guarantee is made. The pinned Wobbly public-API comparison, with no GPL source copying, launch warmup or off-screen parking adoption, is documented in README and the M2 report.

AETHER 1.0 is not release-ready until all milestone tasks and acceptance criteria are completed on macOS, including consented M2 capture evidence and the broader Living Window Gate 0 animation proof.
