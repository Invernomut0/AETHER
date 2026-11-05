# AETHER 1.0.7 (build 8)
## The Desktop, in Motion.

AETHER is a native macOS window-management and visual-effects system built with Swift, AppKit, SwiftUI, ScreenCaptureKit and Metal.

**Product direction:** hybrid native-window control + temporary Metal overlays; effects-first; public APIs as the stable baseline; advanced integrations isolated behind optional adapters.

> Engineering status: M0 and M1 were accepted locally; 1.0.7 (build 8) passed local validation, including three complete post-fix consented capture suites. Both apps were rebuilt and launched, with verified bundle versions and completed Quick Look/Finder refresh. Full M2 platform acceptance and the broader Living Window Gate 0 remain **pending**: physical display/OS-indicator, SDK fault, recovery and macOS 14 runtime checks are not certified; M3 has not started. No private API behavior is assumed to work, and catalog descriptors are not shipped effects.

## Open in Xcode

1. Use full Xcode with Swift 6 support. Local validation used Xcode 27.2 / Swift 6.4.2.
2. Verify `xcrun metal --version`; if missing, install the official component with `xcodebuild -downloadComponent MetalToolchain`.
3. Open the committed `AETHER.xcodeproj`; select `AETHERApp` or `AETHERTestLab`. XcodeGen is optional, not required.
4. Run `bash Scripts/validate.sh` for package build, coverage-enabled tests and both app builds.
5. Launch `.build/Xcode/Build/Products/Debug/AETHER.app` and `AETHER Test Lab.app` with Finder or `open`.

`swift build` / `swift test` validate library targets and tests; they do not build the application entry points. `bash Scripts/build-apps.sh` builds locally ad-hoc-signed bundles. Distribution signing/notarization is not implemented by that script.

Default validation does not auto-run opted-in live mutation gates (M1 fixtures and ScreenCaptureKit consent-dependent capture tests).

Historical pre-snapshot 1.0.7 validation passed three complete capture suites (16 functions / 18 cases executed, two denial skips each), separate native regression 14/14, default validation (34 functions / 39 cases, 20 skips; inventory 54 functions / 61 cases) and both app builds. The earlier focus, closure and startup-timeout failures remain recorded in `Documentation/M2_VALIDATION.md`. GPU tests verify real Metal completion, not physical scanout. Interactive gates require an unlocked desktop, secure input finished and explicit permissions; neither script unlocks the session or grants access.

Version 1.0.7 fixes Stop during startup leaving Start waiting for its callback timeout without abandoning SDK cleanup; 1.0.6 added target interruption/recovery and narrow already-stopped handling. The current increment additionally makes one-shot snapshots the normal preview path, retaining live streams as an explicit diagnostic.

Final current validation passed: inventory **60 functions / 69 expanded cases**, default **34 functions / 39 cases executed, 26 skips**, and both app builds (`/tmp/aether-snapshot-final-validation.log`). Three complete post-fix capture suites each passed **22 functions / 26 cases**, with two denial skips (24-function / 28-case capture inventory); separate native regression passed **14/14**, no skips. Fresh same-instrumentation default/capture/native profiles were explicitly merged: final line coverage is snapshot lease **95.20%**, stream lease **94.95%**, capture coordinator **92.86%**, preview **94.12%**, Metal presenter **87.86%**, total **84.49%**. Earlier failures and pre-snapshot metrics remain retained, not relabeled as final passes. See `Documentation/M2_VALIDATION.md` for exact logs, verified build metadata and local relaunch evidence.

## Current bootstrap and permissions

The dashboard reports live bootstrap readiness, configuration schema, Accessibility and Screen Recording status. Startup does not request permissions or start a capture. Use explicit request buttons to grant capabilities; refresh after changing System Settings, or relaunch if required by macOS.

Configuration is stored at `~/Library/Application Support/AETHER/configuration.json`. Missing files are initialized from schema 1 defaults. Unversioned/schema 0 configurations migrate while retaining recognized settings. Malformed files and future schemas produce a visible startup error without resetting user data; repair the file and retry. Unified logs use subsystem `com.aether.desktop` with `lifecycle`, `configuration`, `permissions` and `windows` categories, excluding window titles and captured content.

## Native windows (M1)

Open **Windows** in AETHER's sidebar and press **Refresh** after changing Accessibility access. The live list includes normal-layer on/off-screen windows exposed by CoreGraphics. **Focus**, **Center** and **Left half** are enabled only for a registered, unambiguous AX match with the required capabilities. Filter by application/title or hide read-only rows. No capture is started and Screen Recording is not required for native control.

Correlation uses PID, global point geometry and titles only when available, with uniqueness in both directions. Identical overlapping windows, inaccessible AX elements and missing process identities remain read-only. Handles are session-scoped, not persistent CG IDs; each operation revalidates the target. Geometry success requires AX and CG convergence, not just a successful setter call. Rejected/partially applied changes are reported without blindly rolling back over user actions; refresh before retrying. Closing the panel cancels its task.

For live integration, quit any running Test Lab instance, then run `bash Scripts/test-window-integration.sh`. This builds the apps, launches real resizable/fixed/overlapping fixtures and explicitly enables tests that move, resize, focus and close **only those fixtures**. It never grants permissions. Ordinary CI skips mutation tests; a skip is not a passed integration gate. See `Documentation/M1_VALIDATION.md` for evidence and outstanding manual checks.

## M2 implementation snapshot (not gate-certified)

The normal snapshot and explicit stream/overlay paths passed local consent-based runtime validation, including three complete post-fix suites. Full platform certification remains pending; see `Documentation/M2_VALIDATION.md` for evidence, retained failures and remaining checks.

After explicitly granting Screen Recording, open **Windows → Snapshot 5s** for one intentionally static image. **Live diagnostic** explicitly selects continuous capture; OS recording indicators are expected there. **Stop preview**, Escape or leaving the panel cancels the transaction. Startup never starts capture; the original window remains interactive and authoritative. Add excluded bundle IDs to `captureExcludedBundleIDs` in configuration and restart after edits; set `effectsEnabled` to false to disable preview startup. Known credential-family exclusions are not an exhaustive protected-content detector.

To validate only controlled Test Lab capture, quit Test Lab and run `bash Scripts/test-capture-integration.sh`. The script requires already-granted Accessibility and Screen Recording and never requests or alters permissions. The suite moves/restores and minimizes/restores fixture A, and closes a separate **M2 Fixture Capture Disposable**. Relaunch Test Lab before repeating the entire live suite; M1's disposable is independent. Never run native mutations and capture tests concurrently.

- `WindowPreviewCoordinator.preview(..., mode: .snapshot)` defaults to one `SCScreenshotManager.captureImage` screenshot: no `SCStream` and no screenshot refresh loop. Serial-owner conversion hands off immutable BGRA `Data`, at most `1600` px per edge.
- Screenshot SDK inputs and successful lease ownership are released before static Metal presentation. Freshness is checked only before first presentation (receipt age at most `1s`); the retained texture is intentionally static for at most `5s`.
- Explicit `.live` diagnostic uses continuous `30fps` `SCStream`: queue depth `3`, newest-only async buffering (`1`), max `1600` px per edge, no audio/cursor/shadows.
- Privacy controls include built-in credential-family exclusions plus user-defined `configuration.captureExcludedBundleIDs`; secure-input and permission checks are enforced.
- Snapshot and stream ownership share one mutually exclusive lease. Screenshot wait/live startup deadline is `5s`; cleanup has an independent `3s` deadline. Stop cancels the Swift waiter, not SDK callbacks: ownership is retained until actual completion/confirmed cleanup, and unconfirmed cleanup blocks both modes until retry. Detailed stream error handling is in `Documentation/API_CONTRACTS.md` and `Documentation/M2_VALIDATION.md`.
- ID-only start is rejected; callers pass a validated `RuntimeWindowHandle` and revalidate before/after asynchronous capture.
- Both modes check permission/secure input and exact CG window ID/PID/on-screen visibility every `100ms` before AX. Callers validate after capture/before presentation; periodic AX identity/frame validation starts `500ms` after monitor start, then repeats every `500ms` plus bounded AX latency. This avoids an immediate duplicate AX query racing native minimization; a CG-only check alone did not fix the retained timeout. No timeout budget or interruption assertion was relaxed. Live additionally requires a first complete frame within `2s` and checks every handoff for age over `1s`.
- Overlay presentation uses a non-activating, non-interactive AppKit panel ordered relative to the native window; drawable size is bounded to `3200` px per edge.
- GPU submission is serialized to one in-flight command; completion uses a 750ms timeout while retaining resources until real command completion; remove is immediate and idempotent.

Current known limitations (still blocking M2 gate acceptance):

- Final current suites cover snapshot/stream capture-to-Metal, exclusions, cancellation, interruptions and ownership recovery; retained failed attempts remain failures. Passing local suites do not certify every lifecycle/failure path or SDK callback order.
- Successful snapshot `framesPresented == 1` means one GPU-completed submission, not physical scanout or refreshed content throughout the static hold.
- Texture-memory diagnostics are estimated (`allocatedTextureBytes`) and do not represent total GPU allocation.
- Preview is diagnostic, not an M3 animation; the original window remains visible and authoritative.
- Physical multi-display/Spaces/full-screen and OS-indicator behavior, SDK faults, crash recovery and macOS 14 runtime remain pending manual/platform checks.

Screen Recording remains required for both preview modes and the approved visual-effects path. Native move/resize can use Accessibility without capture. At Wobbly commit `84147639eb5b285bca75c63ccabfde9a88ad5cfa`, [`Sources/Wobbly/WindowCapture.swift`](https://github.com/jsgrrchg/Wobbly/blob/84147639eb5b285bca75c63ccabfde9a88ad5cfa/Sources/Wobbly/WindowCapture.swift) uses one-shot `SCScreenshotManager.captureSampleBuffer`, not continuous `SCStream`; AETHER independently uses `captureImage` from Apple's public [SCScreenshotManager](https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager) API. This is a public-API design comparison only: no GPL source was copied, and neither Wobbly's launch warmup capture nor off-screen window parking was adopted. No private flags, indicator suppression or permission bypass is used; one-shot capture is not an unconditional guarantee of absent macOS indicators. AeroSpace's private AX-to-window-ID API is not an approved stable dependency.

See `TODO.md`, `IMPLEMENTATION_STATUS.md` and `Documentation/MILESTONE_TASKS.md` for the actual milestone boundary. The owner-provided source repository is [Invernomut0/AETHER](https://github.com/Invernomut0/AETHER), tracked as `origin` on branch `main`. Remote CI results must be checked separately from local validation.

Local validation evidence and remaining checks are recorded in `Documentation/M0_VALIDATION.md`, `Documentation/M1_VALIDATION.md`, and `Documentation/M2_VALIDATION.md` (1.0.7 passed local validation; both rebuilt apps launched; full platform acceptance pending).

The package manifest targets macOS 14.0 and Apple Silicon as the primary architecture. Some advanced APIs and behaviors are availability-gated and must be checked against the SDK installed on the build machine.

## Repository map

- `Sources/AETHERShared`: cross-module models, identifiers, errors and event contracts.
- `Sources/AETHERCore`: orchestration, event bus, permissions and recovery contracts.
- `Sources/AETHERWindowManager`: window discovery, Accessibility control and coordinate mapping.
- `Sources/AETHERCapture`: ScreenCaptureKit capture abstraction.
- `Sources/AETHERRendering`: Metal device, renderer contracts and shaders.
- `Sources/AETHEREffects`: effect registry, descriptors and initial effect implementations.
- `Sources/AETHERPhysics`: deterministic physics primitives and spring solver.
- `Sources/AETHERAnimation`: timeline, keyframes and animation contracts.
- `Sources/AETHERLayouts`: layout tree and basic layout algorithms.
- `Sources/AETHERPersistence`: configuration and preset persistence contracts.
- `Sources/AETHERIntelligence`: rules and optional LLM integration contracts.
- `Sources/AETHERInterface`: SwiftUI dashboard and settings UI.
- `Applications/AETHERTestLab`: real interactive resizable, fixed-size and overlapping window fixtures.
- `Tests`: unit and integration test targets.
- `Documentation`: full product and engineering specification.
- `.github`: Copilot instructions and issue templates.

## First engineering gate: Living Window

Do not build the full effects catalog before validating this pipeline on a real Mac:

1. Discover a test window.
2. Read its geometry using Accessibility where permitted.
3. Capture it with ScreenCaptureKit after explicit user permission.
4. Present a temporary Metal-backed overlay.
5. Animate the captured representation.
6. End the overlay and reconcile the original native window.
7. Verify that focus, visibility and input remain correct.

M3 starts only after the **M2 capture/overlay exit gate** proves a fresh consented frame and reliable removal. M3 then supplies the animation needed to complete the broader Living Window Gate 0; the full effects catalog must wait for that complete gate.

Native window lifecycle interception is not generally available to third-party macOS applications. AETHER must not claim it can replace every system open/close/minimize animation. Trigger effects from AETHER-controlled actions, supported observations, and explicitly configured workflows; provide native fallbacks otherwise.

## Development principles

- Native window state is the source of truth.
- An overlay is temporary and never becomes a permanent interactive replacement for an application window.
- No private API is required for stable functionality.
- Permission denial must degrade gracefully.
- Every capture/overlay operation has cancellation, timeout and cleanup paths.
- Do not move AppKit objects or non-Sendable GPU resources across actors without explicit ownership.
- No placeholder implementation may be marked as production-ready.
- Every milestone must compile, test and document its behavior.

## License

See `LICENSE`. Replace the placeholder license choice before public distribution.
