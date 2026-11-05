# AETHERCapture

ScreenCaptureKit one-shot image and continuous diagnostic-stream ownership.

Current M2 implementation uses actor-owned, mutually exclusive capture semantics:

- `ScreenCaptureCoordinator` owns at most one snapshot **or** stream lease, including pending startup and unconfirmed cleanup.
- Normal `WindowPreviewCoordinator.preview` defaults to `mode: .snapshot`. `captureSnapshot(request:)` uses `WindowSnapshotLease` and one public [SCScreenshotManager](https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager) `captureImage` call: no `SCStream` and no screenshot refresh loop.
- SDK references remain confined to serial owner queues. Snapshot images and stream samples become immutable BGRA `Data`, at most `1600` px per edge, before handoff; snapshot timestamps represent receipt uptime, not a source presentation timestamp.
- Successful screenshot SDK inputs and lease ownership are released before static Metal presentation. **Snapshot 5s** checks freshness only at first presentation (receipt age at most 1s), then intentionally retains the same texture for at most 5s while native/permission monitors continue. `framesPresented == 1` means GPU completion, not physical scanout.
- **Live diagnostic** explicitly selects `.live`: continuous `30fps` `SCStream`, queue depth `3`, newest-only async buffering (`1`), no audio/cursor/shadows. OS recording indicators are expected for this mode.

Lifecycle and cleanup policy:

- Screenshot wait / live startup deadline: 5 seconds. Cleanup deadline: an independent 3 seconds, deliberately not inheriting caller cancellation.
- Stop cancels the pending Swift waiter, including before shareable-content enumeration completes. SDK enumeration/image callbacks are not cancellable: resources and callback ownership remain retained until actual completion, even after either deadline expires. Late enumeration cannot launch a screenshot after cancellation wins admission.
- After suspension, the coordinator checks that delivery is still owned and available/active. Late callbacks cannot deliver cancelled frames or reactivate stopped capture.
- Unconfirmed snapshot cleanup or stream stop retains the lease and blocks both capture modes; the next preview retries cleanup with `stopAllCaptures()` before replacement. Timeouts are errors, not proof of SDK resource release.

Validation/identity policy:

- ID-only stream start is rejected as unsupported.
- `CaptureRequest` requires a validated `RuntimeWindowHandle`.
- Callers must revalidate via `NativeWindowService.validatedWindow` before and after asynchronous capture; cancellation-induced generation invalidation is not relaxed for recovery.
- Preview monitoring checks exact ID/PID/on-screen state through `CGWindowListCopyWindowInfo(.optionIncludingWindow)` every 100ms before AX IPC. Callers validate after capture/before presentation, so the monitor's next AX check is 500ms after monitor start, not an immediate duplicate; subsequent generation/geometry checks retain their 500ms cadence plus bounded AX latency. This combined fix resolves the observed post-GPU AX/minimization race; the earlier CG-only attempt still failed. Timeouts remain failures, budgets were not increased and SDK delays were not injected.

Privacy policy:

- Built-in exclusions cover known credential-manager bundle families.
- User-defined exclusions are read from `configuration.captureExcludedBundleIDs` (restart required after config edits).
- Secure-input and passive Screen Recording checks are enforced in both modes. Recording remains required. No private flags, indicator suppression or permission bypass is used; a one-shot API is not an unconditional guarantee of absent macOS indicators.

Validation: final current local snapshot/stream suites passed. Default validation executes 34 functions / 39 expanded cases with 26 skips (inventory 60/69) and builds both apps with Info.plists verified as 1.0.7/build 8. Focused move/minimize passes two cases, then three full post-fix suites each pass 22 functions / 26 cases with two denial skips (capture inventory 24/28); separate native regression passes 14/14, zero skips. AX/Recording were pre-granted, secure input off, controlled Lab fixtures fresh per full run and native/capture mutations never concurrent. Retain the stale-handle test-only correction (refresh same ID/PID), both full minimize failures, failed CG-only attempt and diagnostic; none is relabeled as a pass. Internal tests expose session IDs only.

Fresh same-instrumentation default/capture-5/native profiles were explicitly merged: final line coverage is `WindowSnapshotLease` 95.20%, `CaptureStreamLease` 94.95%, `ScreenCaptureCoordinator` 92.86%, `WindowPreviewCoordinator` 94.12%, `MetalOverlayPresenter` 87.86%, total 84.49%. Pre-snapshot metrics remain historical, not final current coverage. See `Documentation/M2_VALIDATION.md` for exact logs, verified build/relaunch evidence and pending physical display/OS-indicator, SDK fault, crash-recovery and macOS 14 runtime checks; M3 has not started. OS indicators cannot universally be suppressed and their absence has not been visually certified.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
