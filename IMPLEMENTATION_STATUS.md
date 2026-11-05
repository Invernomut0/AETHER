# Implementation Status

This repository intentionally distinguishes foundations from production-complete capabilities.

## Local milestone baseline — 2026-11-05

Current state: **1.0.8/build 9 locally validated**. The updated 5 November contract requests the **real external Kinetiq engine** and authorizes optional private AX mapping/event-tap/click replay/off-screen parking, disabled by default in AETHER. Helper/build, actual RuntimeModel admission/lifecycle tests, default/live regressions, compatible coverage and both built versions are verified. All four helpers rejected the real running trusted-path engine with exit 2 before any operation (`HELPER_GUARDS_EXIT0`); identity-checked normal engine exit, exact local app relaunches and Quick Look/Finder refresh also completed. M0/M1 stay locally accepted; 1.0.7/build 8 results remain historical. macOS 14 deployment metadata is not runtime certification.

Final launch receipt (**5 November, approximately 12:45**): NSWorkspace finished launch for exact local AETHER PID **69118** and Test Lab PID **69116** (`--m1-fixtures`); CG-owned **AETHER Effect Disposable** and **AETHER Refuses Close** verified, **`KINETIQ_RUNNING=false`**. Quick Look reset/cache reset, Finder Debug-directory update and clean `git diff --check` were recorded. No forced kill was used; exit is not restoration proof. Git commit/origin verification is tracked in `TODO.md`, independently of remote CI and manual acceptance.

Configuration is loaded/migrated before readiness. Startup inspects permissions without prompting; prompts require an explicit button press. The Windows panel connects discovery and verified native control; uncorrelated windows remain read-only. No first-window fallback exists.

M2 status is **current local snapshot/stream regression passed; full physical/platform gate NOT accepted**. Retained failures/historical 1.0.7 evidence remain in `Documentation/M2_VALIDATION.md`. Current results do not waive physical display/OS-indicator, SDK fault, recovery or macOS 14 checks, complete M3/M4 or accept Living Window. Verified receipts/manual steps: `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

| Area | Status in this archive |
|---|---|
| Shared IDs and core models | Foundation implemented |
| Basic event bus | Foundation implemented |
| Core coordinator | M0 configuration bootstrap, cancellation/invalidation, lifecycle logging |
| External Kinetiq engine | Original separate app, no source/assets copied; universal build/upstream 74/74 pass; actual lifecycle/admission 7/7 XCTest passes. Consented launch/connect/normal quit, retained pending/late ownership, 10s waits; no force kill/readiness IPC. Arbitrary late/refused-quit timing remains Review |
| CoreGraphics discovery | Normal-layer on/off-screen inventory, app/display metadata and conservative AX correlation |
| Accessibility window control | Actor-owned registry/generations, focus/geometry verification; `canClose` defaults false for older records, exact-target public AX close/full CG disappearance. Current native regression 17/17, zero skips; AX session line coverage 89.42% |
| ScreenCaptureKit | One-shot captureImage (no SCStream/refresh loop), BGRA up to 1600px; mutually exclusive snapshot/stream ownership, 5s wait/3s cleanup, retained callbacks. Current regression 22 functions / 26 cases passes, two denial skips |
| Metal device | Device discovery foundation |
| Metal renderer | Snapshot 5s, hidden preparation/cached texture, mesh/dissolve; local component/effect tests pass. One in-flight command/750ms wait, resources retained until callback. Line coverage 90.75%, not shader/scanout/fps certification |
| Shader files | Preview/effect pipeline plus starter examples; not a complete catalog |
| Effect registry | Foundation implemented |
| Effects catalog | DeclarativeEffect remains no-op/planned; separate Wobble/Close coordinator passes 6 functions / 7 cases, not a full shipped catalog |
| Physics | Spring/world foundation plus independent 17 × 13 fixed-120Hz lattice; tests pass, WobbleSimulation line coverage 100%, not full physics acceptance |
| Animation | Bounded monotonic manual-effect loop (UI 2s wobble / 1.1s dissolve, max 3s), 60fps target pacing, system OR config Reduce Motion fade. General timeline/tracks and full M3/M4 acceptance pending |
| Layouts | Basic split/leaf tree foundation |
| Persistence | JSON bootstrap and schema 0→1 migration tested; SQLite required for release |
| Intelligence | Rule model foundation; LLM disabled by default |
| Dashboard | Effects hosts real Kinetiq panel: explicit consent, trusted app selection, Start/Connect, Stop/Cancel wait/Refresh and wave-menu/Setup guidance. Windows retains independent public diagnostics, subject to engine-active/pending command interlock; passive discovery allowed. No universal lifecycle API claim |
| Test Lab | Existing native/capture fixtures plus reopenable AETHER Effect Disposable and real AETHER Refuses Close (`windowShouldClose == false`) |
| Automated tests | Default 53 functions / 58 cases passed, 34 skipped functions; effects 6 functions / 7 cases passed, zero skips; capture 22 functions / 26 cases passed, two denial skips; native 17/17 zero skips. Exact logs in visual validation |
| Kinetiq tests | Six passive + one opt-in actual runtime lifecycle: 7/7 XCTest, zero skips, 1.595s. Same-PID connect, independent discovery/no takeover, refused consent, six rejected commands/passive refresh, unchanged fixture and normal exit. No drag/close/readiness certification |

The original **AETHER diagnostic fallback, not Kinetiq**, preserves the visible, interactive original during Wobble and aborts on native changes without rollback. Its Close captures/uploads once, requests the exact registered generation/PID's enabled public AXPress close button, waits for full CG disappearance including off-screen rows within 2s, then renders dissolve. Unconfirmed outcomes forbid automatic retry; Stop overlay cannot undo close and does not stop Kinetiq. Do not run these diagnostics concurrently with the external engine.

Kinetiq is the **actual external engine**: verified built `io.github.invernomut0.Kinetiq`, 0.1.27/build 28, both Mach-O slices minos 14.0; unchanged clean source HEAD `0e1b2a2d22cf77b74bdc595d40c79f842e3af807`. Original Swift 5 concurrency/deprecated SDK warnings remain, no Swift 6 engine claim. No source/assets copied; preserve GPL/NOTICE/third-party/CC-BY notices, without licensing exemption/incompatibility or relicensing claims.

RuntimeModel admission rechecks after configuration await; panels observe every 500ms while visible. Interface is CoreTests-only, not a production Core dependency. The guard is **not a cross-process IPC lock**: an independent engine start during already-in-flight work is not atomically prevented; finish/cancel first. Five compatible explicitly merged profiles give TOTAL **64.48%** source-line coverage (4,491 lines / 1,595 uncovered), with an expanded Interface/Effects perimeter, not a like-for-like 1.0.7 decline or all-branch/shader coverage.

Kinetiq needs its **own** user-granted AX/Recording access; AETHER grants do not transfer. Its raise-time prefetch/recapture, exclusions, physics and motion settings are not governed by AETHER's capture budgets/Reduce Motion. Use wave menu → Setup to select a Close effect (nil is Off). No indicator bypass/absence guarantee. Kinetiq survives AETHER exit; Stop sends normal quit only. Cleanup attempts restoration but process exit never proves all parked windows restored. Manual drag/close, indicators, recovery and full platform acceptance remain pending. See `Documentation/KINETIQ_ENGINE.md`.

AETHER 1.0 is not release-ready until all milestone tasks and acceptance criteria are completed on macOS, including consented M2 capture evidence and the broader Living Window Gate 0 animation proof.
