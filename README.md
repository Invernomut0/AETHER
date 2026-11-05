# AETHER 1.0.8 (build 9)
## The Desktop, in Motion.

AETHER is a native macOS window-management and visual-effects system built with Swift, AppKit, SwiftUI, ScreenCaptureKit and Metal.

**Product direction:** hybrid native-window control + temporary Metal overlays; effects-first; public APIs as the stable baseline; advanced integrations isolated behind optional adapters.

> Engineering status: **1.0.8/build 9 locally validated**. The updated 5 November 2026 contract selects the **real external Kinetiq.app engine**, explicitly permitting optional private AX mapping, event-tap/click replay and temporary off-screen parking. Effects has a consented launch/connect panel; AETHER's independent manual Wobble/Close remains a public-API diagnostic fallback, **not Kinetiq**. Local validation includes active-engine helper guards, exact app relaunches and Quick Look/Finder refresh. Full M2 physical/platform, M3/M4 and Living Window gates remain **unaccepted**; process launch and registry descriptors are not effect certification.

## Use the real Kinetiq engine (experimental opt-in)

**Save work and use disposable Test Lab windows first.** Kinetiq changes real native-window positions, uses private `_AXUIElementGetWindow`, global event taps/click replay and temporary off-screen parking. macOS changes, crashes or failed AX cleanup can leave windows displaced. Native windows stay authoritative; restoration is not guaranteed.

1. Build a trusted separate Kinetiq.app with validated `bash Scripts/build-kinetiq.sh [sourcecheckout]` (default sibling `/Users/lorenzov/dev/Wobbly`), delegating to original upstream `scripts/build-app.sh` with local ad-hoc signing by default. The verified build leaves upstream source unchanged/clean. Output remains `<sourcecheckout>/build/Kinetiq.app`, **not inside AETHER.app**.
2. Open **Effects**, choose that bundle, read the warnings, check experimental consent and press **Start / Connect Kinetiq**. AETHER bootstrap, selecting an app and Refresh never launch it; **Start / Connect explicitly launches or connects** and may show Kinetiq's own permission prompts. Matching metadata/resources are not authentication; use only a trusted build.
3. Grant **Kinetiq's own** Accessibility and Screen Recording access manually if prompted; AETHER's grants do not transfer. Restart Kinetiq only if macOS requires it. Open its **wave menu**, verify **Kinetiq Enabled** and **Drag from Title Bar**, then **Setup… → Close**, choosing e.g. **Fire**. Nil close selection is **Off**; saved settings can differ from upstream defaults.
4. Open Test Lab manually; drag an empty disposable by its title bar and close only that disposable. Kinetiq uses its real physics/shaders. AETHER has no readiness/settings RPC: a running PID is not proof of working effects, and Setup is where effects are configured.
5. Use **Stop Kinetiq** or wave menu → **Quit Kinetiq**. **Kinetiq survives AETHER exit/page dismissal.** Stop requests normal termination only, never force-kill. Its cleanup attempts native restoration; inspect windows/input/overlays afterward rather than inferring success from exit.

Start/Stop waits are bounded to 10 seconds. Cancel wait/timeout cannot revoke an issued OS request; pending/late launch ownership remains and blocks replacement. Actual RuntimeModel admission rejects focus/move/capture/effects while active/pending, including independent instances; passive discovery stays allowed. Its post-configuration-await recheck and 500ms visible-panel observation do **not** create a cross-process IPC lock: an independent external launch during already-in-flight AETHER work is not atomically prevented. Finish/cancel AETHER work before external launch. Stop Kinetiq before AETHER diagnostic or mutation suites; arbitrary late/refused-quit timing remains manual/source-contract review.

Kinetiq's own settings govern capture/exclusions/motion. AETHER's 1600px snapshot budgets, exclusions, `effectsEnabled` and Reduce Motion do **not** automatically apply; external capture can prefetch/recapture on raise, not strictly one image per gesture. No permission/indicator bypass or absent-indicator guarantee. Actual built metadata: **0.1.27/build 28**, `io.github.invernomut0.Kinetiq`; vtool verified both arm64/x86_64 Mach-O slices have `LC_BUILD_VERSION minos 14.0`. Original upstream Swift 5 concurrency/deprecated x86 SDK warnings remain; AETHER's Swift 6 build pass does not certify the engine as Swift 6.

See `Documentation/KINETIQ_ENGINE.md` for the updated contract, lifecycle, GPL/NOTICE/CC-BY attribution boundary and pending drag/close/recovery evidence. No Kinetiq source/assets/binary are copied into AETHER targets or distribution, and no unilateral AETHER relicensing or general GPL exemption/incompatibility is asserted.

## Open in Xcode

1. Use full Xcode with Swift 6 support. Historical local validation used Xcode 27.2 / Swift 6.4.2.
2. Verify `xcrun metal --version`; if missing, install the official component with `xcodebuild -downloadComponent MetalToolchain`.
3. Open the committed `AETHER.xcodeproj`; select `AETHERApp` or `AETHERTestLab`. XcodeGen is optional, not required.
4. Run `bash Scripts/validate.sh` for package build, coverage-enabled tests and both app builds.
5. Launch `.build/Xcode/Build/Products/Debug/AETHER.app` and `AETHER Test Lab.app` with Finder or `open`.

`swift build` / `swift test` validate library targets and tests; they do not build the application entry points. `bash Scripts/build-apps.sh` builds locally ad-hoc-signed bundles. Distribution signing/notarization is not implemented by that script.

Default validation does not auto-run opted-in native, capture, effect or Kinetiq lifecycle gates. `AETHER_RUN_KINETIQ_INTEGRATION=1` enables real launch/connect/normal exit and actual RuntimeModel admission checks with fresh Test Lab `--m1-fixtures`, including Effect Disposable; it does not automate drag/click-close or attest event-tap readiness.

### Verified local receipts — 5 November 2026

The validation logs below exited 0; both built AETHER Info.plists are **1.0.8/build 9**. Mutation suites used fresh controlled fixtures sequentially with Kinetiq stopped.

| Check | Actual result | Log in `/tmp/` |
|---|---|---|
| Swift 6 build, default coverage tests, both Xcode apps | 53 functions / 58 cases passed (19 XCTest + 34 Swift Testing); 34 skipped functions (one Kinetiq opt-in + 33 Swift Testing) | `aether-kinetiq-final-validation.log` |
| Original external universal Kinetiq build | Passed; unchanged clean source HEAD `0e1b2a2d22cf77b74bdc595d40c79f842e3af807` | `aether-kinetiq-engine-build.log` |
| Original upstream tests | 74/74, no failures | `aether-kinetiq-upstream-tests.log` |
| Lifecycle + actual runtime admission | 7/7 XCTest, zero skips, 1.595s | `aether-kinetiq-final-live.log` |
| AETHER effects | 6 functions / 7 cases, zero skips, 9.880s | `aether-kinetiq-final-effects.log` |
| Capture | 22 functions / 26 cases passed, two denial skips (selected inventory 24/28), 21.408s | `aether-kinetiq-final-capture.log` |
| Native control/close | 17/17, zero skips, 3.877s | `aether-kinetiq-final-native.log` |

Five fresh compatible saved profiles were explicitly merged; `aether-kinetiq-final-coverage.log` reports **64.48% total source-line coverage** (4,491 lines / 1,595 uncovered). Interface/Effects test linkage expands the perimeter: not a like-for-like drop from 1.0.7, nor all-branch/shader coverage. Exact metrics, profile paths and actual runtime test scope are in `Documentation/VISUAL_EFFECTS_VALIDATION.md`. Editor errors were absent and whitespace checks clean at the verified checkpoint.

Final local receipts (**5 November, approximately 12:45**): all four helpers (`Scripts/build-kinetiq.sh`, `Scripts/test-effect-integration.sh`, `Scripts/test-capture-integration.sh`, `Scripts/test-window-integration.sh`) were invoked with the real trusted-path Kinetiq bundle running. Each exited **2**, explicitly requesting quit/stop Kinetiq before any build, permission, fixture or test operation began; the enclosing check reported **`HELPER_GUARDS_EXIT0`**. The identity-checked selected `NSRunningApplication` then terminated normally with actual exit confirmed, without forced kill. Exact local bundles completed launch: **AETHER PID 69118**, **Test Lab PID 69116** (`--m1-fixtures`), with CG-owned **AETHER Effect Disposable** and **AETHER Refuses Close** titles verified; **`KINETIQ_RUNNING=false`**. Quick Look reset/cache reset and Finder Debug-directory update completed; `git diff --check` was clean. These receipts prove launch/guards/refresh, not visual effects or window restoration. Git commit/origin verification is tracked in `TODO.md`; remote CI review is separate from local publication and product acceptance.

Historical **1.0.7/build 8** local snapshot/stream results, coverage, retained failures and app-relaunch evidence remain in `Documentation/M2_VALIDATION.md`; they are not current 1.0.8 validation. GPU completion is not physical scanout. Interactive checks require an unlocked desktop, secure input finished and explicit permissions; no script unlocks the session or grants access. See `Documentation/TESTING.md` for suite selection and coverage rules.

## Current bootstrap and permissions

The dashboard reports live bootstrap readiness, configuration schema, Accessibility and Screen Recording status. Startup does not request permissions or start a capture. Use explicit request buttons to grant capabilities; refresh after changing System Settings, or relaunch if required by macOS.

Configuration is stored at `~/Library/Application Support/AETHER/configuration.json`. Missing files are initialized from schema 1 defaults. Unversioned/schema 0 configurations migrate while retaining recognized settings. Malformed files and future schemas produce a visible startup error without resetting user data; repair the file and retry. Unified logs use subsystem `com.aether.desktop` with `lifecycle`, `configuration`, `permissions` and `windows` categories, excluding window titles and captured content.

## Native windows (M1)

Open **Windows** in AETHER's sidebar and press **Refresh** after changing Accessibility access. The live list includes normal-layer on/off-screen windows exposed by CoreGraphics. **Focus**, **Center** and **Left half** are enabled only for a registered, unambiguous AX match with the required capabilities. Filter by application/title or hide read-only rows. No capture is started and Screen Recording is not required for native control.

Correlation uses PID, global point geometry and titles only when available, with uniqueness in both directions. Identical overlapping windows, inaccessible AX elements and missing process identities remain read-only. Handles are session-scoped, not persistent CG IDs; each operation revalidates the target. Geometry success requires AX and CG convergence, not just a successful setter call. Rejected/partially applied changes are reported without blindly rolling back over user actions; refresh before retrying. Closing the panel cancels its task.

For live integration, quit any running Test Lab instance, then run `bash Scripts/test-window-integration.sh`. This builds the apps, launches real resizable/fixed/overlapping fixtures and explicitly enables tests that move, resize, focus and close **only those fixtures**. It never grants permissions. Ordinary CI skips mutation tests; a skip is not a passed integration gate. See `Documentation/M1_VALIDATION.md` for evidence and outstanding manual checks.

## Snapshot and live diagnostics (M2 platform gate still pending)

The normal snapshot and explicit stream/overlay paths passed current **1.0.8** regression (22 functions / 26 cases, two denial skips); full platform certification remains pending. See receipts above and `Documentation/M2_VALIDATION.md` for historical 1.0.7 evidence and retained failures.

After explicitly granting Screen Recording, open **Windows**, filter for **AETHER Test Lab**, then choose **Snapshot 5s** for one intentionally static image. Watch the target title bar and macOS menu bar **before, during and after** capture. Do not select **Live diagnostic** for this normal-path check; it is an optional continuous-capture positive control, with expected recording indicators and possible recent-use indicators afterward. Record **visible / not visible / not determined**; actual observation is still user-pending. **Stop overlay**, Escape or leaving the panel cancels the transaction. Startup never starts capture; the original window remains interactive and authoritative. Add exclusions to `captureExcludedBundleIDs` in configuration and restart after edits; set `effectsEnabled` to false to disable preview/effect startup. Known credential-family exclusions are not exhaustive. Full steps: `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

To validate only controlled Test Lab capture, quit Test Lab and run `bash Scripts/test-capture-integration.sh`. The script requires already-granted Accessibility and Screen Recording and never requests or alters permissions. The suite moves/restores and minimizes/restores fixture A, and closes a separate **M2 Fixture Capture Disposable**. Relaunch Test Lab before repeating the entire live suite; M1's disposable is independent. Never run native mutations and capture tests concurrently.

- `WindowPreviewCoordinator.preview(..., mode: .snapshot)` defaults to one `SCScreenshotManager.captureImage` screenshot: no `SCStream` and no screenshot refresh loop. Serial-owner conversion hands off immutable BGRA `Data`, at most `1600` px per edge.
- Screenshot SDK inputs and successful lease ownership are released before static Metal presentation. Freshness is checked only before first presentation (receipt age at most `1s`); the retained texture is intentionally static for at most `5s`.
- Explicit `.live` diagnostic uses continuous `30fps` `SCStream`: queue depth `3`, newest-only async buffering (`1`), max `1600` px per edge, no audio/cursor/shadows.
- Privacy controls include built-in credential-family exclusions plus user-defined `configuration.captureExcludedBundleIDs`; secure-input and permission checks are enforced.
- Snapshot and stream ownership share one mutually exclusive lease per capture owner; preview/effect coordinators own separate instances, with serialized UI commands. Screenshot wait/live startup deadline is `5s`; cleanup has an independent `3s` deadline. Stop cancels the Swift waiter, not SDK callbacks: ownership is retained until actual completion/confirmed cleanup, and unconfirmed cleanup blocks both modes on that owner until retry. Detailed stream error handling is in `Documentation/API_CONTRACTS.md` and `Documentation/M2_VALIDATION.md`.
- ID-only start is rejected; callers pass a validated `RuntimeWindowHandle` and revalidate before/after asynchronous capture.
- Both modes check permission/secure input and exact CG window ID/PID/on-screen visibility every `100ms` before AX. Callers validate after capture/before presentation; periodic AX identity/frame validation starts `500ms` after monitor start, then repeats every `500ms` plus bounded AX latency. This avoids an immediate duplicate AX query racing native minimization; a CG-only check alone did not fix the retained timeout. No timeout budget or interruption assertion was relaxed. Live additionally requires a first complete frame within `2s` and checks every handoff for age over `1s`.
- Overlay presentation uses a non-activating, non-interactive AppKit panel ordered relative to the native window; drawable size is bounded to `3200` px per edge.
- GPU submission is serialized to one in-flight command; completion uses a 750ms timeout while retaining resources until real command completion; remove is immediate and idempotent.

Current known limitations (still blocking M2 gate acceptance):

- Current 1.0.8 capture regression passes alongside retained historical 1.0.7 evidence; neither certifies every lifecycle/failure path or SDK callback order. Retained failed attempts remain failures.
- Successful snapshot `framesPresented == 1` means one GPU-completed submission, not physical scanout or refreshed content throughout the static hold.
- Texture-memory diagnostics are estimated (`allocatedTextureBytes`) and do not represent total GPU allocation.
- Snapshot/Live preview is diagnostic, distinct from the explicit effect actions below; it keeps the original visible and authoritative.
- Physical multi-display/Spaces/full-screen and OS-indicator behavior, SDK faults, crash recovery and macOS 14 runtime remain pending manual/platform checks.

## AETHER diagnostic effects — separate fallback, not Kinetiq

Stop Kinetiq before using this fallback. The instructions below describe only AETHER's original public-API coordinator, not the requested external engine; command admission must remain blocked while any Kinetiq instance/launch is active or unresolved.

Use only **AETHER Effect Disposable** for the manual Wobble/Close checks. Open or reopen it with Test Lab's **Open Effect Disposable** button, then refresh AETHER's list. **Save real work first**: the close action is destructive, not a visual simulation.

- **Wobble 2s** (`WindowEffectCoordinator`, `.wobble`): one captured snapshot animated by an independent 17 × 13 spring lattice at fixed 120Hz simulation steps. The original stays visible and interactive; this is not a global native-drag hook. Native movement/resize/minimize/disappearance interrupts the overlay without rollback.
- **Close with dissolve…** (`.dissolveClose`): requires confirmation, one capture and one texture upload; prepares the overlay hidden, sends one public AX close request to the exact registered generation/PID and enabled `AXPress` close button, then waits for full CG inventory disappearance (including off-screen windows, 2s verification deadline). **Only then** plays the original procedural dissolve for 1.1s. Refusal/save dialogs/unconfirmed closure do not authorize animation; `NativeWindowCloseError.outcomeUnconfirmed` requires inspection, not automatic retry. Stop removes the overlay but cannot undo a native close.
- System **or** configuration Reduce Motion selects a fade instead of deformation/noise. Animation duration is bounded to 3s; 60fps pacing is a scheduling target, not a measured performance result. One GPU submission may be in flight; its 750ms wait deadline never releases resources before the real completion callback. The uploaded texture is cached until removal (in-flight ownership can outlive it).
- These AETHER diagnostic effects reuse the one-shot `SCScreenshotManager.captureImage` path (5s capture wait, independent 3s cleanup, existing privacy controls, no `SCStream`). Panels cannot become key/main and do not intercept input. This coordinator implements no universal red-button/Cmd-W interception, native hiding, off-screen parking or close rollback; Kinetiq's authorized experimental parking/input integration is separate.

`WindowCapabilities.canClose` defaults to false, including when decoding older records; a discovered close action does not guarantee the application will accept it. Test Lab includes **AETHER Refuses Close**, a real `windowShouldClose == false` fixture. Automated refusal coverage is separate from the disposable-only manual demo.

`Scripts/test-effect-integration.sh` opts in with `AETHER_RUN_EFFECT_INTEGRATION=1` and passed six functions / seven cases with real fixtures, zero skips. Native-close regression uses existing `AETHER_RUN_WINDOW_INTEGRATION=1`, not a separate variable. Never run native/capture/effect mutation suites concurrently; each full suite needs fresh disposable fixtures. See `Documentation/TESTING.md` and the verified receipts/manual review table in `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

Screen Recording remains required for AETHER snapshots/visual diagnostics; native AX control alone does not require capture. The earlier reference-only boundary is superseded by the explicit external Kinetiq opt-in described above. Its private mapping/parking/input techniques are authorized in its own process, **not copied into AETHER**; capture can prefetch/recapture. No private indicator flags, suppression or permission bypass is authorized, and no capture mode guarantees absent system indicators. Historical 1.0.7 documentation describes the earlier public-only implementation, not the new engine bridge.

See `TODO.md`, `IMPLEMENTATION_STATUS.md` and `Documentation/MILESTONE_TASKS.md` for the actual milestone boundary. The owner-provided source repository is [Invernomut0/AETHER](https://github.com/Invernomut0/AETHER), tracked as `origin` on branch `main`. Remote CI results must be checked separately from local validation.

Historical local evidence is in `Documentation/M0_VALIDATION.md`, `Documentation/M1_VALIDATION.md` and `Documentation/M2_VALIDATION.md`. Verified current receipts and still-pending manual observations are in `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

The package manifest targets macOS 14.0 and Apple Silicon as the primary architecture. Some advanced APIs and behaviors are availability-gated and must be checked against the SDK installed on the build machine.

## Repository map

- `Sources/AETHERShared`: cross-module models, identifiers, errors and event contracts.
- `Sources/AETHERCore`: orchestration, event bus, permissions and recovery contracts.
- `Sources/AETHERWindowManager`: window discovery, Accessibility control and coordinate mapping.
- `Sources/AETHERCapture`: ScreenCaptureKit capture abstraction.
- `Sources/AETHERRendering`: Metal device, renderer contracts and shaders.
- `Sources/AETHEREffects`: effect registry and declarative descriptors; generic effect lifecycles remain no-op/planned.
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

The updated 5 November request permits the optional real Kinetiq experiment and the separate bounded diagnostic slice while the full **M2 physical/platform gate remains unaccepted**. It does not waive that gate, accept Living Window Gate 0 or complete M3/M4. General milestone progression/catalog expansion still require outstanding evidence, including manual Kinetiq drag/close, input, indicators and recovery.

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

See `LICENSE`. Replace the placeholder license choice before public distribution; this integration does not relicense AETHER. External Kinetiq remains GPL-3.0-or-later with its original `LICENSE`, `NOTICE`, third-party notices and CC-BY-4.0 texture attribution retained in its checkout. No Kinetiq code/assets/binary are embedded or redistributed by this bridge. Separate processes are an architectural boundary, not a legal exemption; review obligations before any future bundling/reuse/distribution. See `Documentation/KINETIQ_ENGINE.md`.
