# AETHER 1.0.5 (build 6)
## The Desktop, in Motion.

AETHER is a native macOS window-management and visual-effects system built with Swift, AppKit, SwiftUI, ScreenCaptureKit and Metal.

**Product direction:** hybrid native-window control + temporary Metal overlays; effects-first; public APIs as the stable baseline; advanced integrations isolated behind optional adapters.

> Engineering status: M0 and M1 were accepted locally. The consented M2 capture/overlay proof now passes on the local Mac (`AX=true`, `Recording=true`, secure input off), including cancellation and native geometry/focus checks. Full M2 platform acceptance and the broader Living Window Gate 0 remain **pending**: physical display/recovery checks and M3 animation are not certified. No private API behavior is assumed to work, and catalog descriptors are not shipped effects.

## Open in Xcode

1. Use full Xcode with Swift 6 support. Local validation used Xcode 27.2 / Swift 6.4.2.
2. Verify `xcrun metal --version`; if missing, install the official component with `xcodebuild -downloadComponent MetalToolchain`.
3. Open the committed `AETHER.xcodeproj`; select `AETHERApp` or `AETHERTestLab`. XcodeGen is optional, not required.
4. Run `bash Scripts/validate.sh` for package build, coverage-enabled tests and both app builds.
5. Launch `.build/Xcode/Build/Products/Debug/AETHER.app` and `AETHER Test Lab.app` with Finder or `open`.

`swift build` / `swift test` validate library targets and tests; they do not build the application entry points. `bash Scripts/build-apps.sh` builds locally ad-hoc-signed bundles. Distribution signing/notarization is not implemented by that script.

Default validation does not auto-run opted-in live mutation gates (M1 fixtures and ScreenCaptureKit consent-dependent capture tests).

Latest consented capture validation: three consecutive suites passed with 12 functions executed and two permission-denial functions inapplicable because Recording was granted; the separate native suite passed all 14 tests. The initial capture suite failed a focus assertion when macOS UserNotificationCenter became frontmost; no assertion or engine code was changed before the successful repetitions. GPU tests verify real Metal submissions, not physical scanout. Interactive gates require an unlocked desktop, secure input finished and explicit permissions; neither script unlocks the session or grants access.

Final 1.0.5 default validation passed Swift/both app builds and 34 test functions / 39 cases, with 16 explicit skips. A separate live coverage rerun also passed (12 executed, two denial tests skipped); see `Documentation/M2_VALIDATION.md` for measured coverage and all failed attempts/prerequisites.

## Current bootstrap and permissions

The dashboard reports live bootstrap readiness, configuration schema, Accessibility and Screen Recording status. Startup does not request permissions or start a capture. Use explicit request buttons to grant capabilities; refresh after changing System Settings, or relaunch if required by macOS.

Configuration is stored at `~/Library/Application Support/AETHER/configuration.json`. Missing files are initialized from schema 1 defaults. Unversioned/schema 0 configurations migrate while retaining recognized settings. Malformed files and future schemas produce a visible startup error without resetting user data; repair the file and retry. Unified logs use subsystem `com.aether.desktop` with `lifecycle`, `configuration`, `permissions` and `windows` categories, excluding window titles and captured content.

## Native windows (M1)

Open **Windows** in AETHER's sidebar and press **Refresh** after changing Accessibility access. The live list includes normal-layer on/off-screen windows exposed by CoreGraphics. **Focus**, **Center** and **Left half** are enabled only for a registered, unambiguous AX match with the required capabilities. Filter by application/title or hide read-only rows. No capture is started and Screen Recording is not required for native control.

Correlation uses PID, global point geometry and titles only when available, with uniqueness in both directions. Identical overlapping windows, inaccessible AX elements and missing process identities remain read-only. Handles are session-scoped, not persistent CG IDs; each operation revalidates the target. Geometry success requires AX and CG convergence, not just a successful setter call. Rejected/partially applied changes are reported without blindly rolling back over user actions; refresh before retrying. Closing the panel cancels its task.

For live integration, quit any running Test Lab instance, then run `bash Scripts/test-window-integration.sh`. This builds the apps, launches real resizable/fixed/overlapping fixtures and explicitly enables tests that move, resize, focus and close **only those fixtures**. It never grants permissions. Ordinary CI skips mutation tests; a skip is not a passed integration gate. See `Documentation/M1_VALIDATION.md` for evidence and outstanding manual checks.

## M2 implementation snapshot (not gate-certified)

The capture/overlay vertical slice has passed local consent-based runtime validation. Full platform certification remains pending the manual checks below; see `Documentation/M2_VALIDATION.md` for exact evidence and the initial focus failure.

After explicitly granting Screen Recording, open **Windows → Preview 5s**. **Stop preview**, Escape or leaving the panel cancels the transaction. Startup never starts capture; the original window remains interactive and authoritative. Add excluded bundle IDs to `captureExcludedBundleIDs` in the configuration file and restart after edits; set `effectsEnabled` to false to disable preview startup. Known credential-family exclusions are not an exhaustive detector of protected content.

To validate only controlled Test Lab capture, quit Test Lab and run `bash Scripts/test-capture-integration.sh`. The script requires already-granted Accessibility and Screen Recording and never requests or alters permissions.

- Capture callback path implemented with immutable BGRA `Data` copied on a serial capture-owner queue.
- `SCStreamConfiguration` currently targets bounded throughput: queue depth `3`, newest-only async buffering (`1`), max `1600` px per edge, `30fps`, no audio/cursor/shadows.
- Privacy controls include built-in credential-family exclusions plus user-defined `configuration.captureExcludedBundleIDs`; secure-input and permission checks are enforced.
- Capture session ownership is single-lease actor-driven with start deadline `5s` and stop deadline `3s`; failed stop retains the lease and the next preview retries cleanup before opening a new stream.
- ID-only capture start is rejected; callers must pass a validated `RuntimeWindowHandle` and revalidate through `NativeWindowService.validatedWindow` before/after capture start.
- Core preview orchestration limits runtime to 5 seconds, requires first complete frame within 2 seconds, drops stale handoff older than 1 second, monitors permission/secure-input every 100ms, and revalidates identity/frame every 500ms with bounded AX latency.
- Overlay presentation uses a non-activating, non-interactive AppKit panel ordered relative to the native window; drawable size is bounded to `3200` px per edge.
- GPU submission is serialized to one in-flight command; completion uses a 750ms timeout while retaining resources until real command completion; remove is immediate and idempotent.

Current known limitations (still blocking M2 gate acceptance):

- Consented tests validate fresh ScreenCaptureKit frames reaching Metal, configured exclusions, cancellation and removal; they do not certify every lifecycle/failure path.
- `framesPresented` currently counts GPU command completion, not verified on-screen presentation.
- Texture-memory diagnostics are estimated (`allocatedTextureBytes`) and do not represent total GPU allocation.
- Preview is diagnostic, not an M3 animation; the original window remains visible and authoritative.
- Physical multi-display Spaces/full-screen behavior and crash-recovery guarantees remain manual validation items.

Screen Recording remains part of the approved main visual-effects path. Native move/resize can use Accessibility without capture, but deforming another app's captured content requires authorization. [Wobbly](https://github.com/jsgrrchg/Wobbly) uses the same capture-plus-Metal principle and also requires Screen Recording. It is GPL-3.0-or-later: it is a reference, not a source dependency. AeroSpace is a useful tiling reference but documents a private AX-to-window-ID API, which is not an approved stable dependency for AETHER. No permission bypass is proposed.

See `TODO.md`, `IMPLEMENTATION_STATUS.md` and `Documentation/MILESTONE_TASKS.md` for the actual milestone boundary. The owner-provided source repository is [Invernomut0/AETHER](https://github.com/Invernomut0/AETHER), tracked as `origin` on branch `main`. Remote CI results must be checked separately from local validation.

Local validation evidence and remaining manual checks are recorded in `Documentation/M0_VALIDATION.md`, `Documentation/M1_VALIDATION.md`, and `Documentation/M2_VALIDATION.md` (local live proof passed; full platform acceptance pending).

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
