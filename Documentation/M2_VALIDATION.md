# M2 Validation — Implementation Slice, Gate Pending

Date: 2026-11-04. Version: **1.0.4 (build 5)**.

## Decision and consent

M2 is **not accepted**. The latest passive test-host check reports Accessibility granted, Screen Recording denied and secure input enabled. The desktop is locked; the frontmost application is `com.apple.loginwindow`. No unlock, Recording request or ScreenCaptureKit capture was initiated in this pass. Granting access remains an explicit user action; no bypass is provided. M3 has not started.

## Implemented boundaries

- `WindowPreviewCoordinator` revalidates the session-scoped native handle before and after capture startup. It does not move, hide, resize or focus the native window.
- `CaptureStreamLease` confines ScreenCaptureKit objects and sample buffers to its serial queue. Only copied, immutable BGRA `Data` crosses isolation boundaries.
- Capture configuration: maximum edge 1600px, 30fps, queue depth 3, newest-only async buffering of 1, no cursor/audio/shadows. This safety path is CPU-copy based, not a zero-copy or 60/120fps performance claim.
- Start has a 5s deadline; cleanup has its own 3s deadline independent of parent cancellation. Unconfirmed stop retains ownership and blocks replacement until cleanup can be retried. Late callbacks still perform cleanup.
- Known credential bundle families and configured exclusions are denied; secure input and passive Recording checks guard startup and delivery. The denylist is not exhaustive and cannot identify every protected surface. Add other bundle IDs to `captureExcludedBundleIDs` and restart after configuration edits.
- Preview lasts at most 5s, requires a first frame within 2s and rejects handoffs older than 1s. Permission/secure-input checks run every 100ms; native identity/frame checks every 500ms plus bounded AX IPC latency. Moving, resizing, minimizing or losing the target aborts; no rollback overwrites native user actions.
- The temporary Metal panel is non-activating, input-transparent and ordered relative to the selected native window at normal level. Display coordinates use points and actual backing scale; drawable edge is capped at 3200px.
- GPU work is serialized. A 750ms completion deadline closes a failed presentation, but GPU resources remain owned until actual completion. Removal invalidates the transaction immediately and is idempotent.
- `framesPresented` counts GPU-completed submissions, not physical scanout. Texture-byte diagnostics estimate owned textures, not total GPU memory. Static diagnostic preview is not the M3 motion engine.

## Automated evidence

`bash Scripts/validate.sh` passed: Swift build, coverage-enabled default tests and both Xcode application builds, verified as version 1.0.4/build 5. The inventory is 50 test functions (55 expanded cases): **33 functions / 38 cases executed successfully; 17 functions skipped** on the locked host. Skips are 11 opted-in M1 fixtures, three consented capture tests and three read-only AX-boundary tests unavailable during secure input. No editor diagnostics were reported.

- All 14 opted-in M1 native fixture tests passed earlier in this pass. Later retries failed fixture discovery while the desktop was locked: direct probes showed AXWindows entries with role `AXApplication`, missing frame attributes and refused app activation. Removing duplicate fixture processes did not restore AX availability; the eventual secure-input/loginwindow observation identified the environmental blocker. Production correlation remained unchanged and correctly rejected those proxies. The final interactive rerun remains blocked, not passed.
- Real Metal tests upload actual system `Terminal.app` icon pixels through a BGRA context into a real overlay. They check GPU completion, panel/input/focus properties and removal. This is **not** a ScreenCaptureKit test or a visual scanout certification.
- Capture component tests cover observed desktop request validation, privacy policy, cancellation/deadline helper behavior, passive-denial paths when eligible handles exist and idle cleanup. Conditional prerequisite messages mean the respective branch was not exercised; they are not integration evidence.
- Three consent-dependent tests (fresh captured preview, configured exclusion and cancellation teardown) remain opt-in and unexecuted. `CaptureStreamLease` output handling therefore has no live runtime coverage yet.

Final aggregate **line coverage** (not region coverage): package 45.24%; `MetalOverlayPresenter` 81.79%; `BGRAPixelFrame` 91.67%; `CallbackDeadline` 93.02%; `ScreenCaptureCoordinator` 16.67%; `CaptureStreamLease` and `WindowPreviewCoordinator` 0%. This explicitly does not certify active capture/orchestration. Default request tests exercised rejection of observed ineligible descriptors, not registered-handle startup while locked.

Both integration scripts passed shell syntax checks and returned the expected exit code 2 before build/capture/mutation on this host. Secure-input detection is a conservative public-API prerequisite, not a universal lock detector. The three Metal tests passed GPU/logical-panel assertions; no physical visual inspection was possible while locked. Nonblocking CoreSimulator mismatch, SwiftPM Metal-bundle creator and local ad-hoc signing warnings remain.

## Reproduce the consented gate

Unlock the desktop, finish secure input, grant Accessibility and Screen Recording explicitly to the test host, quit Test Lab, then run `bash Scripts/test-capture-integration.sh`. It checks existing permissions/secure input without prompting, builds both apps, launches controlled Test Lab fixtures and enables only `CapturePipelineTests` with `AETHER_RUN_CAPTURE_INTEGRATION=1`. Missing prerequisites exit before build/capture; explicitly enabled tests also fail missing prerequisites rather than silently accepting them. No other application's content is captured by these live tests. Rerun `bash Scripts/test-window-integration.sh` separately for the final native regression gate.

In AETHER, use **Windows → Preview 5s** after explicit permission grant. **Stop preview**, Escape or leaving the panel cancels the transaction. Startup never starts capture. Set `effectsEnabled` to false in configuration and restart to disable preview startup globally.

## Remaining acceptance work

- Run the consented ScreenCaptureKit-to-Metal tests and manually verify fresh content, cancellation and absence of orphan panels.
- Exercise permission revocation in flight, protected content, target closure/minimization, late callbacks and recovery from failed stop/GPU completion.
- Verify physical multi-display/Retina placement, Spaces/full-screen ordering, interaction and unexpected process termination.
- Complete stress/soak and macOS 14 runtime checks. Deployment targeting alone does not certify runtime behavior.
- Remote CI was not checked; local tests do not certify release signing/notarization or the full Living Window animation gate.