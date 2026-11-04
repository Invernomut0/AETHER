# AETHER 1.0.2
## The Desktop, in Motion.

AETHER is a native macOS window-management and visual-effects system built with Swift, AppKit, SwiftUI, ScreenCaptureKit and Metal.

**Product direction:** hybrid native-window control + temporary Metal overlays; effects-first; public APIs as the stable baseline; advanced integrations isolated behind optional adapters.

> Engineering status: M0 bootstrap is implemented and locally built/tested on macOS. M1 window control and the Living Window capture/overlay gate remain incomplete. No private API behavior is assumed to work, and catalog descriptors are not shipped effects.

## Open in Xcode

1. Use full Xcode with Swift 6 support. Local validation used Xcode 27.2 / Swift 6.4.2.
2. Verify `xcrun metal --version`; if missing, install the official component with `xcodebuild -downloadComponent MetalToolchain`.
3. Open the committed `AETHER.xcodeproj`; select `AETHERApp` or `AETHERTestLab`. XcodeGen is optional, not required.
4. Run `bash Scripts/validate.sh` for package build, coverage-enabled tests and both app builds.
5. Launch `.build/Xcode/Build/Products/Debug/AETHER.app` and `AETHER Test Lab.app` with Finder or `open`.

`swift build` / `swift test` validate library targets and tests; they do not build the application entry points. `bash Scripts/build-apps.sh` builds locally ad-hoc-signed bundles. Distribution signing/notarization is not implemented by that script.

## Current bootstrap and permissions

The dashboard reports live bootstrap readiness, configuration schema, Accessibility and Screen Recording status. Startup does not request permissions or start a capture. Use the explicit request buttons to grant capabilities; refresh after changing System Settings, or relaunch if required by macOS.

Configuration is stored at `~/Library/Application Support/AETHER/configuration.json`. Missing files are initialized from schema 1 defaults. Unversioned/schema 0 configurations migrate while retaining recognized settings. Malformed files and future schemas produce a visible startup error without resetting user data; repair the file and retry. Unified logs use subsystem `com.aether.desktop` with `lifecycle`, `configuration` and `permissions` categories, excluding window titles and captured content.

Screen Recording remains part of the approved main visual-effects path. Native move/resize can use Accessibility without capture, but deforming another app's captured content requires authorization. [Wobbly](https://github.com/jsgrrchg/Wobbly) uses the same capture-plus-Metal principle and also requires Screen Recording. It is GPL-3.0-or-later: it is a reference, not a source dependency. AeroSpace is a useful tiling reference but documents a private AX-to-window-ID API, which is not an approved stable dependency for AETHER. No permission bypass is proposed.

See `TODO.md`, `IMPLEMENTATION_STATUS.md` and `Documentation/MILESTONE_TASKS.md` for the actual milestone boundary. The owner-provided source repository is [Invernomut0/AETHER](https://github.com/Invernomut0/AETHER), tracked as `origin` on branch `main`. Remote CI results must be checked separately from local validation.

Local validation evidence and remaining manual checks are recorded in `Documentation/M0_VALIDATION.md`.

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
- `Applications/AETHERTestLab`: controlled test-app specification and starter target.
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
