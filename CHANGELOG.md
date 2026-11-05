# Changelog

## 1.0.7 — M2 snapshots and lifecycle ownership (2026-11-05)
- Reproduce Stop during an observed inactive startup lease ending in the five-second callback timeout; retain the failed test log rather than treating it as cancellation.
- Keep the startup deadline queue-owned and settle its Swift waiter when Stop is requested. SDK callbacks/resources still require normal confirmed cleanup; unconfirmed stop still retains ownership and blocks replacement. Recheck owned/active state after Start suspends.
- Add internal session-ID-only ownership observation and three opt-in real tests: startup cancellation, Stop during startup, and three concurrent Start/cancelled-or-normal Stop cycles. Assert real fresh BGRA recovery on the same owner, unique session IDs, bounded stream termination and idempotent cleanup; no mocked SDK callbacks.
- Historical **pre-snapshot** validation passed default tests (34 functions / 39 cases, 20 skips; inventory 54 functions / 61 cases), both app builds, three capture suites (16 functions / 18 cases, two denial skips each), and separate native regression 14/14.
- Preserve and explicitly merge historical default/native/capture profiles after a filtered run replaced the profile. Pre-snapshot line coverage: stream lease 94.95%, capture coordinator 89.47%, preview 93.39%, Metal presenter 87.86%, aggregate 81.62%; these are not final current snapshot metrics.
- Make `WindowPreviewCoordinator.preview` default to `.snapshot`, surfaced as **Snapshot 5s**: one `SCScreenshotManager.captureImage`, immutable BGRA up to 1600px per edge, no `SCStream` or screenshot refresh loop. Release successful snapshot ownership before static Metal presentation; freshness applies only at first presentation and `framesPresented == 1` means GPU completion, not scanout.
- Bound screenshot waiting to 5s with independent 3s cleanup; retain non-cancellable SDK callback ownership until actual completion and enforce one mutually exclusive snapshot/stream lease. Preserve native/permission monitors during the intentionally static hold of at most 5s.
- Keep **Live diagnostic** as explicit continuous 30fps `SCStream` capture with expected OS recording indicators. Screen Recording remains required in both modes; no private flags, suppression, bypass or unconditional absence-of-indicators guarantee. The pinned Wobbly comparison is public-API design only; no GPL source, launch warmup capture or off-screen parking was adopted (links in README/M2 validation).
- Retain the failed stale-AX-handle recovery test and its test-only correction (refresh the same CG ID/PID, no production relaxation), both failed snapshot minimize suites, the unsuccessful CG-visibility-only attempt and the diagnostic locating the immediate post-GPU monitor AX query racing minimization. Final production handling checks exact CG ID/PID/on-screen visibility every 100ms before AX and schedules the next AX check 500ms after monitor start, avoiding a duplicate of caller validation after capture/before presentation. Timeouts remain failures; budgets were not increased and no SDK delay was injected.
- Final current local validation passed default tests (**34 functions / 39 cases executed, 26 skips**; inventory **60 functions / 69 cases**) and both app builds. Focused post-fix movement/minimization passed two cases, followed by three full post-fix capture suites (**22 functions / 26 cases executed, two denial skips each**, 21.282s / 21.126s / 21.150s) with fresh controlled Lab fixtures and separate native **14/14**, zero skips (3.050s). Native/capture mutations were never concurrent. Exact logs are in `Documentation/M2_VALIDATION.md`.
- Explicitly merge fresh same-instrumentation `/tmp/aether-snapshot-{default,capture-5,native}.profdata`: final **line** coverage in `/tmp/aether-snapshot-final-coverage.log` is snapshot lease **95.20%**, stream lease **94.95%**, capture coordinator **92.86%**, preview **94.12%**, Metal presenter **87.86%**, total **84.49%**. Earlier pre-snapshot metrics remain historical, not final current coverage.
- Verify both built Info.plists as 1.0.7 (build 8), relaunch the exact local app bundles (Test Lab PID 50953 with `--m1-fixtures`, AETHER PID 50955), and complete Quick Look reset/cache refresh and Finder update. Remote CI review remains separate and pending. Full M2 physical/platform, OS-indicator, SDK fault-order, crash-recovery and macOS 14 runtime acceptance remain pending; M3 has not started.

## 1.0.6 — M2 target interruption and recovery (2026-11-04)
- Add opt-in real-window movement, minimization and closure scenarios after the first GPU-completed captured frame; verify overlay removal, preserved native action and another preview using the same coordinator.
- Add an independent M2 disposable Test Lab window; restore non-disposable fixtures and require a fresh Test Lab before repeating the suite.
- Reproduce closure cleanup failing because SCK had already stopped. Accept only `SCStreamErrorDomain` / `attemptToStopStreamState` when startup is no longer pending, then remove output normally; retain ownership for all other unconfirmed stops.
- Pass default validation/both app builds, four post-fix capture suites (13 functions / 15 cases, two denial skips each) and native regression 14/14; record the real failure baseline and final coherent live coverage (lease 93.56%, preview 93.39% lines).
- Bump both app bundles to 1.0.6 (build 7). Full M2 physical/platform acceptance and M3 animation remain pending.

## 1.0.5 — Consented M2 live evidence (2026-11-04)
- Record three consecutive successful capture suites with pre-granted Accessibility/Recording and secure input off: 12 functions executed, two denial tests inapplicable per run.
- Verify real ScreenCaptureKit frames reach Metal, overlays are removed, exclusions reject capture and cancellation preserves native geometry; separate M1 regression passes 14/14.
- Preserve the initial focus assertion failure that observed macOS UserNotificationCenter becoming frontmost; no assertion or capture/render engine implementation was changed before the successful repetitions.
- Replace stale dashboard/validation-script gate text and bump both app bundles to 1.0.5 (build 6).
- Keep full M2 platform acceptance, physical scanout, recovery, release certification and M3 animation explicitly pending.

## 1.0.4 — M2 first implementation, gate pending (2026-11-04)
- Integrate the first Living Window capture/overlay implementation slice without promoting it to gate acceptance.
- Add ScreenCaptureKit output-path ownership with serial callback processing and immutable BGRA frame copies.
- Configure bounded capture flow for preview transactions (queue depth 3, newest-only async delivery, capped frame size, 30fps baseline for this slice).
- Add privacy/permission enforcement in the capture path (secure-input checks, known credential-family exclusions, user exclusions from configuration).
- Add preview lifecycle safeguards: strict deadlines, stale-frame rejection, periodic permission/identity revalidation and cleanup retries.
- Add Metal overlay presentation lifecycle hardening (non-activating/non-interactive panel, serialized GPU work, idempotent remove).
- Expand M2 test coverage with capture and Metal suites, including opt-in live ScreenCaptureKit tests that require pre-granted consent.
- Fail live script preflight safely on secure input/locked sessions; retain read-only behavior when AX exposes non-window proxies. Default build/test validation passes, while interactive gates remain explicitly pending.
- Increment app version to 1.0.4 (build 5).
- Keep the M2 capture/overlay exit gate unaccepted: latest host state remained `AX=true`, `Recording=false`, so live ScreenCaptureKit output-path runtime validation is still pending. M3 animation will subsequently complete the broader Living Window Gate 0.

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
