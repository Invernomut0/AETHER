# M2 Validation — Local Live Proof Passed, Platform Acceptance Pending

Date: 2026-11-04. Evidence publication: **1.0.5 (build 6)**; capture/render implementation introduced in 1.0.4.

## Decision and consent

The **local consented capture/overlay proof passed**. Full M2 platform acceptance is still pending the manual checks below; M3 has not started and Living Window Gate 0 is not accepted. After the user's explicit permission grant, passive checks reported `AX=true`, `Recording=true`, `secureInput=false` on an unlocked desktop. Tests captured only controlled Test Lab fixtures. No permission request, TCC change, automatic unlock or notification dismissal was performed.

## Consented live evidence

- The first `Scripts/test-capture-integration.sh` run built both apps and exercised the real capture path, but **failed** its unchanged frontmost-PID assertion: Test Lab PID 38649 changed to PID 22293. A process lookup identified PID 22293 as `/System/Library/CoreServices/UserNotificationCenter.app/Contents/MacOS/UserNotificationCenter`. This identifies the observed focus recipient, not proof of the notification's cause. The failure is retained, not counted as a pass.
- Without changing engine code or test assertions, three consecutive `AETHER_RUN_CAPTURE_INTEGRATION=1 swift test --filter CapturePipelineTests` runs passed. Each inventory contains 14 functions: **12 executed successfully and two skipped** because permission-denial tests do not apply when Recording is granted.
- The three opt-in tests now verify fresh ScreenCaptureKit pixels reaching Metal with GPU completion, overlay removal, native geometry/focus preserved, configured exclusion rejection, and cancellation after at least one real frame with immediate panel removal and native frame unchanged.
- Separate `AETHER_RUN_WINDOW_INTEGRATION=1 swift test --filter NativeWindowTests` regression passed **14/14**, with no skips. It was not run concurrently with capture tests because it moves/focuses/closes fixtures.
- Retained local logs: `/tmp/aether-m2-consented-live.log` (initial failure), `/tmp/aether-m2-stable-2.log`, `/tmp/aether-m2-stable-3.log` and `/tmp/aether-m2-consented-native.log`; the first successful repetition is also in the coding-session terminal transcript. Logs are local artifacts, not source-controlled captures.
- This proves the basic local capture/overlay transaction, not physical scanout, animation, stress bounds or crash recovery. No captured pixels were persisted.

## Final 1.0.5 validation

- `bash Scripts/validate.sh` completed successfully: Swift build, coverage-enabled default tests and both Xcode application builds. Inventory remains 50 functions / 55 expanded cases; **34 functions / 39 cases executed successfully, 16 functions skipped**. Skips are 11 native opt-ins, three capture opt-ins and two denial tests inapplicable under granted Recording. Default aggregate line coverage was **47.30%**. Log: `/tmp/aether-m2-consented-validation.log`.
- A subsequent focused coverage attempt correctly failed all three live prerequisites because Test Lab was no longer running after the build. No reason for its disappearance was established; this is not counted as a pass. Log: `/tmp/aether-m2-consented-coverage-tests.log`.
- After relaunching the built Test Lab, `AETHER_RUN_CAPTURE_INTEGRATION=1 swift test --enable-code-coverage --filter CapturePipelineTests` passed: **12 functions executed, two denial functions skipped**, including all three consented live tests. Log: `/tmp/aether-m2-consented-coverage-rerun.log`.
- The coverage report generated after that live run (`/tmp/aether-m2-consented-coverage.log`) reports **line**, not region, coverage: `CaptureStreamLease` **88.70%**, `ScreenCaptureCoordinator` **72.22%**, `WindowPreviewCoordinator` **88.43%**, `MetalOverlayPresenter` **87.07%**. This report follows the default and focused executions; it does not certify the untested failure branches or replace the separate default-run metrics above.
- No editor diagnostics were reported. Engine code and test assertions are unchanged; this publication updates evidence, static status wording and app version metadata.

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

## Historical baseline before consent (1.0.4)

`bash Scripts/validate.sh` passed: Swift build, coverage-enabled default tests and both Xcode application builds, verified as version 1.0.4/build 5. The inventory is 50 test functions (55 expanded cases): **33 functions / 38 cases executed successfully; 17 functions skipped** on the locked host. Skips are 11 opted-in M1 fixtures, three consented capture tests and three read-only AX-boundary tests unavailable during secure input. No editor diagnostics were reported.

- All 14 opted-in M1 native fixture tests passed before screen lock. Later locked retries failed fixture discovery: direct probes showed AXWindows entries with role `AXApplication`, missing frame attributes and refused app activation. Removing duplicate fixture processes did not restore AX availability; secure-input/loginwindow observations identified the blocker. Correlation correctly rejected those proxies. The subsequent unlocked native regression now passes as recorded above.
- Real Metal tests upload actual system `Terminal.app` icon pixels through a BGRA context into a real overlay. They check GPU completion, panel/input/focus properties and removal. This is **not** a ScreenCaptureKit test or a visual scanout certification.
- Capture component tests cover observed desktop request validation, privacy policy, cancellation/deadline helper behavior, passive-denial paths when eligible handles exist and idle cleanup. Conditional prerequisite messages mean the respective branch was not exercised; they are not integration evidence.
- At this historical baseline, the three consent-dependent tests were unexecuted. They have since passed in the live runs above; they remain opt-in rather than part of default validation.

Historical aggregate **line coverage** (not region coverage): package 45.24%; `MetalOverlayPresenter` 81.79%; `BGRAPixelFrame` 91.67%; `CallbackDeadline` 93.02%; `ScreenCaptureCoordinator` 16.67%; `CaptureStreamLease` and `WindowPreviewCoordinator` 0%. These figures describe the locked default run, not the subsequent consented live executions. Default request tests then exercised rejection of observed ineligible descriptors, not registered-handle startup while locked.

Both integration scripts passed shell syntax checks and returned the expected exit code 2 before build/capture/mutation on this host. Secure-input detection is a conservative public-API prerequisite, not a universal lock detector. The three Metal tests passed GPU/logical-panel assertions; no physical visual inspection was possible while locked. Nonblocking CoreSimulator mismatch, SwiftPM Metal-bundle creator and local ad-hoc signing warnings remain.

## Reproduce the consented gate

Unlock the desktop, finish secure input, grant Accessibility and Screen Recording explicitly to the test host, quit Test Lab, then run `bash Scripts/test-capture-integration.sh`. It checks existing permissions/secure input without prompting, builds both apps, launches controlled Test Lab fixtures and enables only `CapturePipelineTests` with `AETHER_RUN_CAPTURE_INTEGRATION=1`. Missing prerequisites exit before build/capture; explicitly enabled tests also fail missing prerequisites rather than silently accepting them. No other application's content is captured by these live tests. Rerun `bash Scripts/test-window-integration.sh` separately for the final native regression gate.

In AETHER, use **Windows → Preview 5s** after explicit permission grant. **Stop preview**, Escape or leaving the panel cancels the transaction. Startup never starts capture. Set `effectsEnabled` to false in configuration and restart to disable preview startup globally.

## Remaining acceptance work

- Manually verify physical fresh-content presentation, interaction and absence of orphan panels; successful GPU/logical-panel assertions are not visual scanout certification.
- Exercise permission revocation in flight, protected content, target closure/minimization, late callbacks and recovery from failed stop/GPU completion.
- Verify physical multi-display/Retina placement, Spaces/full-screen ordering, interaction and unexpected process termination.
- Complete stress/soak and macOS 14 runtime checks. Deployment targeting alone does not certify runtime behavior.
- Remote CI was not checked; local tests do not certify release signing/notarization or the full Living Window animation gate.