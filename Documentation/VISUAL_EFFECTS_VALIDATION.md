# Visual Effects Validation — 1.0.8 (build 9)

## Status and scope — 5 November 2026

**1.0.8/build 9 locally validated.** Verified local receipts include build/tests/coverage, all four active-engine helper guards, identity-checked normal Kinetiq exit, exact local app relaunches and Quick Look/Finder refresh. The final launch/guard/refresh receipt is dated **5 November 2026, approximately 12:45**. Physical observations remain separate Review items; Git commit/origin verification is tracked in `TODO.md`, independently of remote CI.

The user's updated 5 November request selects the **real external Kinetiq.app engine**, authorizing optional private AX mapping, event-tap/click replay and temporary off-screen parking. It remains disabled by default in AETHER. The earlier manual Wobble/Close is a **separate public-API diagnostic fallback**, not the requested engine. **Full M2 physical/platform, M3/M4, Living Window and release acceptance remain pending**. Historical 1.0.7/build 8 evidence is not current validation. See `KINETIQ_ENGINE.md`.

## Manual K — actual Kinetiq engine (not the fallback below)

**Status: user-pending; save real work first and test only disposable windows.** Kinetiq changes native positions, parks off-screen and can replay clicks; OS/private AX failures or crashes may leave windows displaced. Native windows remain authoritative. No restoration guarantee, TCC editing, auto-allow or recording-indicator bypass is authorized.

1. Both built AETHER Info.plists were verified as 1.0.8/build 9. For this manual run record the exact running bundles, trusted external Kinetiq.app canonical path/version/build, macOS/display/scale/Spaces state, existing indicator state and both apps' own grants. Built Kinetiq metadata is 0.1.27/build 28, not proof this manual session is running it. Do not collect unrelated titles/pixels.
2. Finish/cancel AETHER window operations and overlays first, including before independently starting Kinetiq. In **Effects**, select trusted Kinetiq.app, read warnings, check risk consent and **Start / Connect**. AETHER bootstrap, selection and Refresh remain passive; **Kinetiq Start / Connect explicitly launches or connects** and can show its own permission prompts. A PID or “Process running” is **not readiness evidence**; resolve those prompts manually. AETHER grants do not transfer. Record any restart requested by macOS.
3. Open Kinetiq's **wave menu**. Verify **Kinetiq Enabled** and **Drag from Title Bar**; title-bar/tilt/glide defaults can be overridden by saved settings. Open **Setup…** and explicitly select **Close → Fire** or the desired real effect; nil Close selection is **Off**. AETHER has no settings/readiness RPC. Record actual chosen settings, including Kinetiq exclusions/motion behavior, not AETHER defaults.
4. Open Test Lab manually and **Open Effect Disposable**. Verify the empty disposable before dragging its title bar. Observe actual Kinetiq deformation/native handoff, final native position, focus/input and no orphan overlay. Do not press AETHER Wobble 2s and call that Kinetiq. Runtime command-admission rejection and passive discovery passed the automated test below; this does not certify visual behavior. The guard is **not a cross-process IPC lock**: an external engine independently starting during an already-in-flight AETHER action is not atomically prevented. Finish/cancel AETHER work before external launch.
5. Record title/menu-bar indicators **BEFORE / DURING / AFTER**, separately, as **visible / not visible / not determined**. Kinetiq can prefetch/recapture on raise via `captureSampleBuffer`; do not assert one image per gesture, AETHER snapshot limits or absent indicators. Recent-use persistence is not automatically continuous capture or cleanup failure.
6. With real work saved, close **only AETHER Effect Disposable** using Kinetiq's supported native close interaction. Observe the actual selected close effect, native outcome, surviving windows and input; do not substitute AETHER Close with dissolve, inject clicks or automatically retry an uncertain close. Native save-sheet/refusal behavior is app-dependent, not a universal interception guarantee. Reopen/refresh the disposable for a deliberate repeat.
7. Test **Stop Kinetiq** and, in a separate run, wave menu → **Quit Kinetiq**, inspecting positions/input/overlays afterward. Only normal termination is requested; no force-kill. Upstream `cancelAll` attempts synchronous AX restoration, but a successful exit does not prove all windows restored. Retain failure/uncertainty and inspect before normal retry. Record displaced windows explicitly; do not blindly restore stale coordinates over user changes.
8. Separately verify **Cancel wait/page dismissal**: an issued OS launch/quit cannot be revoked; pending ownership blocks replacement and late handles remain manageable. Kinetiq continues after AETHER quits; deliberately use its wave-menu Quit afterward. An unresolved launch, termination refusal or timeout is not a pass. Do not terminate an uncertain parking engine forcibly for this test.

Kinetiq's settings/capture/exclusions and motion policy are independent: AETHER's `captureExcludedBundleIDs`, `effectsEnabled`, 1600px limits and system/config Reduce Motion handling **do not automatically apply**. Observe the actual upstream behavior and record any unmet accessibility/privacy requirement. Multi-display/Spaces/full-screen, OS-version/private AX and crash-recovery acceptance need separate controlled evidence; do not deliberately crash an engine over real documents.

## Separate fallback protocol — Kinetiq must be stopped

All Snapshot/Wobble/Close/Live contracts and Manual A–C below refer only to **AETHER's independent public-API diagnostics**, not external Kinetiq. Do not run these operations or their mutation suites while any Kinetiq instance/launch is active or unresolved. Stop overlay/Escape only controls AETHER visuals, not the external process.

## Implemented behavior to verify

- **Snapshot 5s**: one selected-window public `SCScreenshotManager.captureImage`, intentionally static hold, no `SCStream` or image-refresh loop. Existing capture privacy exclusions, Screen Recording consent, 5s wait/independent 3s cleanup and ownership until non-cancellable SDK callback completion apply to snapshots and effects. Successful snapshot capture ownership is released before rendering.
- **Wobble 2s** (`.wobble`): one captured/uploaded texture, independent 17 × 13 spring lattice with fixed 120Hz simulation steps. The original remains visible and interactive. This is a manual snapshot preview, **not global native-drag integration**; a native geometry/visibility/identity change interrupts it without rollback.
- **Close with dissolve…** (`.dissolveClose`): UI confirmation; one capture/upload and hidden renderer preparation; one real public AX close request for the registered generation/PID and an enabled pressable close button; **full CG inventory disappearance including off-screen rows** within a 2s verification deadline; **then** an original 1.1s procedural dissolve. A hidden/minimized window, save sheet, refusal or AX success code is not closure proof.
- **Failure safety**: `NativeWindowCloseError.outcomeUnconfirmed` means close may still complete. Do not automatically retry, hide the native window or claim rollback. **Stop removes the overlay; it cannot undo a native close.** No universal red-button or Cmd-W interception is implemented.
- **Rendering/motion**: animation accepts 0.2...3s (capture/AX/cleanup deadlines are separate); UI uses 2s wobble / 1.1s dissolve. System OR config Reduce Motion selects a fade instead of deformation/noise. Approximately 60fps pacing is a scheduling target, **not measured achieved fps**. One GPU command may be in flight; its 750ms wait deadline never releases resources before the real completion callback. The source texture is cached until removal; in-flight ownership can outlive removal. GPU frame counts are not physical scanout.
- **Overlay**: non-activating panel, never key/main, input-pass-through. Wobble never hides/moves/parks the original; Close really closes it. No indicator bypass, private flags or unconditional absence-of-system-indicators guarantee.

## Prerequisites and destructive-action warning

1. Both built bundles have verified 1.0.8/build 9 Info.plists and completed exact-local-bundle launch verification (AETHER PID 69118; Test Lab PID 69116 with `--m1-fixtures`). Recheck running identities for each later manual session. Do not test an older running build and label its results 1.0.8.
2. Use an unlocked local Mac with secure input finished. Explicitly grant Accessibility and Screen Recording to the actual host/app identities being tested; refresh permissions and restart only if macOS requires it. No permission grants or unlocks are automated.
3. Use only real controlled Test Lab content. **Save all real work first. Close with dissolve sends a destructive native close request. Do not use a document containing unsaved work.** Confirm the app, title and PID before every action.
4. Open exactly one external **AETHER Test Lab**, with startup fixtures (`--m1-fixtures`) when running automated suites. For manual Wobble/Close, press **Open Effect Disposable**; the exact title is **AETHER Effect Disposable**. The button brings an existing instance forward or reopens it after closure, allowing safe manual repetition. Refresh AETHER after reopening; an old generation/CG ID must not be reused.
5. Keep native/capture/effect mutation suites sequential, never concurrent. Full suites consume disposables; use fresh Test Lab startup fixtures between suites. The separate **AETHER Refuses Close** fixture is a real native window returning false from `windowShouldClose`; its refusal coverage is automated, not the disposable-only manual demo.
6. Record macOS version, display/scale, Spaces/full-screen state, effective Reduce Motion, grants, test date and bundle identities. Do not store captured private pixels or unrelated window titles in logs.

## Manual A — recording-indicator observation (normal snapshot path)

1. In AETHER open **Windows**, select **Refresh**, and filter the application list for **AETHERTestLab / AETHER Test Lab** (use the displayed application name, not an unrelated similarly titled window). Choose the controlled **AETHER Effect Disposable** row and verify its title/PID.
2. **BEFORE**: observe the target window's title bar and the macOS menu bar. Record each separately as **visible / not visible / not determined**. Note existing indicators or recent-use state from earlier capture; do not assume a clean baseline.
3. Choose **Snapshot 5s**, **not Live diagnostic**. **DURING** the capture and static hold, observe the same title/menu-bar areas. Check that the source remains visible and interactive, and the overlay never becomes key or intercepts clicks. Use the fixture's real **Update** button if helpful: the captured representation is intentionally static, not refreshed content.
4. **AFTER** automatic removal, observe both areas again and record any persistence/recency separately. Confirm the native fixture remains usable and there is no orphan overlay. A recent-use indicator after cleanup is not by itself proof of a continuing stream.
5. Repeat Snapshot once to check cleanup/reuse, recording a new observation rather than copying the previous result. If not clearly observable, use **not determined**, not an inferred absence.
6. **Optional positive control only**: run **Live diagnostic** separately, label it continuous `SCStream`, and observe the expected system recording indications before/during/after. Record persistent recent-use state before subsequent snapshot checks. Do not treat Live as the normal effect path, suppress indicators or change private flags.

These observations remain **user-pending**. A one-shot public API cannot guarantee universal absence across macOS versions, displays, title bars or menu-bar presentations.

## Manual B — non-destructive wobble preview

1. Reopen/select **AETHER Effect Disposable** only, refresh its row and verify the current PID/title/handle. Do not select the refusal fixture or a real document for this manual demo.
2. With system and configuration Reduce Motion off, press **Wobble 2s**. Expect elastic deformation of one snapshot over the still-visible native original, followed by fade/removal. Do not interpret it as native drag deformation or continuously updated captured content.
3. Verify the panel does not become key/main or intercept input. Native fixture interactions remain available; a deliberate click may legitimately change focus, so distinguish that from overlay activation.
4. Repeat while deliberately moving the native disposable: expect interruption/removal with the **user's new native position retained**, not rollback. Inspect/refresh before repeating; do not count a timeout or cleanup error as a successful interruption.
5. Repeat with **Stop overlay**, with **Escape while AETHER's Windows panel has focus**, and by navigating away from Windows, one run per action. Expect immediate visual removal and task cleanup, then a fresh operation can start. Escape is not a global event hook; the input-pass-through overlay cannot consume it.
6. Enable system Reduce Motion (or configuration `reduceMotion`, loaded at startup) and repeat: expect fade only. The effective value is system **OR** config; disabling config cannot override system Reduce Motion. Record both settings, then restore preferences deliberately if changed for the test.

## Manual C — confirmed destructive close followed by dissolve

1. Press Test Lab's **Open Effect Disposable**, refresh AETHER, and select **AETHER Effect Disposable only**. Save real work first and verify the target title/PID; **Close** capability must be available. `canClose` means a supported request, not guaranteed acceptance.
2. Press **Close with dissolve…**, then **Cancel** first. Confirm no capture/close effect was started and the native fixture remains. Repeat and read the real-close warning before choosing the destructive **Close with dissolve** confirmation.
3. Expect the native target to close before the roughly 1.1s captured dissolve. Check native disappearance and the surviving Test Lab windows, not merely a fading image. The dissolve must not run as a substitute for confirmed closure. GPU completions and visual appearance alone do not prove full-inventory disappearance; use the associated automated/log evidence too.
4. If a sheet/refusal/error or unconfirmed outcome occurs, do not report success and **do not automatically retry**. Inspect the owning app/native state first: the request may still complete. Stop/Escape/navigation removes visuals but cannot restore a window already closed.
5. Reopen via **Open Effect Disposable**, refresh and repeat only on the newly correlated instance. During a separate run test Stop/navigation after dissolve begins; the native close must remain closed, and no overlay may remain. Do not promise that Escape after losing AETHER focus is globally handled.
6. Repeat with Reduce Motion enabled: native closure must still be confirmed before a simple fade. This is not a reversible animation or interception of arbitrary red-button/Cmd-W actions.

## Automated fallback coverage — passed locally

`Scripts/test-effect-integration.sh` opts in with **`AETHER_RUN_EFFECT_INTEGRATION=1`** and runs `WindowEffectIntegrationTests` with real external fixtures/capture/GPU work. The final effects run passed **six functions / seven expanded cases**, zero skips, in **9.880s**:
- Wobble completion/reuse, including a configuration Reduce Motion true iteration.
- Cancellation after presentation and same-owner reuse.
- Native movement interruption; test-controlled restoration, no effect rollback.
- Privacy exclusion/pre-cancellation for both kinds (two cases).
- Real native refusal: no close, no dissolve/overlay, typed unconfirmed outcome.
- Successful disposable close/dissolve and same-owner wobble recovery on a surviving fixture.

Native-close regression uses **`AETHER_RUN_WINDOW_INTEGRATION=1`**, not a separate `_TESTS` opt-in. Component tests include physics identities/stability bounds, renderer/cache ownership and capability Codable compatibility; consult `TESTING.md`. Missing opt-in/consent is not a passed gate.

## Verified local receipts and remaining review

Owner for build/live/docs/publication: **AETHER engineering**. Physical observations: **user**, with engineering review. All final run logs below exited **0**; native/capture/effects used sequential fresh controlled Test Lab fixtures with Kinetiq stopped. Historical 1.0.7 metrics remain historical.

| Evidence | Status | Required observation / receipt |
|---|---|---|
| Swift 6 package build, default coverage tests, both Xcode apps | Passed — `/tmp/aether-kinetiq-final-validation.log` | 53 functions / 58 expanded cases passed: 19 XCTest + 34 Swift Testing; 34 skipped functions: one Kinetiq opt-in XCTest + 33 Swift Testing. Counts are parsed outcomes, not an unchecked global inventory |
| Both built AETHER Info.plists | Verified | AETHER.app and AETHER Test Lab.app: **1.0.8/build 9**; exact launch verified separately below |
| Native regression | Passed — `/tmp/aether-kinetiq-final-native.log` | **17/17**, zero skips, **3.877s** |
| Capture regression | Passed — `/tmp/aether-kinetiq-final-capture.log` | **22 functions / 26 cases**, two inapplicable denial skips; selected suite inventory 24/28, **21.408s** |
| Effects suite | Passed — `/tmp/aether-kinetiq-final-effects.log` | **6 functions / 7 cases**, zero skips, **9.880s** |
| External Kinetiq helper/build/identity | Passed — `/tmp/aether-kinetiq-engine-build.log` | `Scripts/build-kinetiq.sh` delegates to original upstream; clean unchanged checkout HEAD `0e1b2a2d22cf77b74bdc595d40c79f842e3af807`; external **0.1.27/build 28**, `io.github.invernomut0.Kinetiq`; actual Mach-O arm64/x86_64 `LC_BUILD_VERSION minos 14.0` verified with vtool |
| Original upstream tests | Passed — `/tmp/aether-kinetiq-upstream-tests.log` | Actual `swift test --package-path /Users/lorenzov/dev/Wobbly`: **74/74**, no failures; upstream Swift 5 concurrency and deprecated x86 SDK build warnings retained, no engine Swift 6 claim |
| Kinetiq passive/lifecycle and actual runtime admission | Passed — `/tmp/aether-kinetiq-final-live.log` | **7/7 XCTest**, zero skips, **1.595s**; actual launch/same-PID connect, independent discovery without takeover, refused consent to existing-instance connect, six runtime command rejections, passive refresh and normal Stop/exit; scope below |
| Pending/late launch and refused/timed-out quit timing | Review — manual/source contract | Ownership retention implemented; arbitrary SDK delays/refusal timing not forcibly injected or runtime-certified |
| Actual Kinetiq disposable drag/Close effect, own settings/permissions | Pending — user | Manual K, actual wave menu/Setup selection (nil Close is Off); PID is not readiness |
| Kinetiq indicators, input, normal Stop/Quit/native restoration | Pending — user | Separate before/during/after observations; no inherited AETHER budgets/Reduce Motion or exit-based restoration certification |
| Current compatible line coverage | Passed — `/tmp/aether-kinetiq-final-coverage.log` | Fresh five-profile explicit merge; exact line metrics and changed instrumentation perimeter below |
| Helper active-engine rejection | Passed — actual runtime; `HELPER_GUARDS_EXIT0` | `Scripts/build-kinetiq.sh`, `Scripts/test-effect-integration.sh`, `Scripts/test-capture-integration.sh`, `Scripts/test-window-integration.sh` invoked with real Kinetiq running from its exact trusted bundle. Each returned **exit 2**, explicitly requesting quit/stop Kinetiq before any build/permission/fixture/test operation began. All four `bash -n` checks also passed |
| Selected Kinetiq normal termination | Verified — actual exit true | Selected `NSRunningApplication` identity checked before normal `terminate()`; actual exit confirmed, **no forced kill**. Exit is not native-restoration evidence |
| Diagnostics and whitespace | Verified by main workflow | No editor errors; `git diff --check` clean at the supplied checkpoint |
| Exact app launches and fixture identity | Verified — NSWorkspace finished launch | `.build/Xcode/Build/Products/Debug/AETHER.app`, **PID 69118**; `.build/Xcode/Build/Products/Debug/AETHER Test Lab.app`, **PID 69116**, `--m1-fixtures`. CG-owned **AETHER Effect Disposable** and **AETHER Refuses Close** titles verified; **`KINETIQ_RUNNING=false`** |
| Quick Look/cache/Finder refresh | Completed | `qlmanage -r`, `qlmanage -r cache` and `osascript` Finder update of the Debug directory completed |
| Snapshot title-bar indicators BEFORE / DURING / AFTER | Pending — user; not determined | Record visible / not visible / not determined at each stage |
| Snapshot menu-bar indicators BEFORE / DURING / AFTER | Pending — user; not determined | Record visible / not visible / not determined; distinguish recent use |
| Optional Live positive control and recent-use persistence | Pending — user; not determined | Label separate continuous diagnostic, or explicitly record not run |
| Disposable wobble, native visibility/input/focus, interruption | Pending — user | Actual visual/native observations; no global-drag claim |
| Confirmation/cancel, real close → dissolve, reopen | Pending — user | Exact disposable only; no automatic retry/rollback |
| Stop / Escape / navigation and no-orphan cleanup | Pending — user | Separate wobble/close runs, noting irreversible close and focus context |
| System OR config Reduce Motion fade | Pending — user | Effective settings and observed behavior for each effect |
| Physical displays/Spaces/full-screen, scanout, recovery, SDK faults, macOS 14 runtime | Pending — M2/platform gate | Separate acceptance evidence; slice does not waive these checks |
| Repository publication receipt | Doing — AETHER engineering | Atomic 1.0.8 commit/push prepared for final review; record actual Git commit and origin verification afterward. Not a milestone/readiness gate; tracked in `TODO.md` |
| Remote CI | Review — AETHER engineering | Inspect remote results independently of local publication; no remote CI pass is asserted |

After final Swift validation, only shell guards (separately syntax/integration checked) and documentation changed. Final guard/launch/refresh receipts do not certify manual effects, indicator absence, event-tap readiness or native-window restoration.

### Runtime interlock scope

The opted-in lifecycle test now imports the actual `AetherRuntimeModel` via `@testable AETHERInterface`, with Interface added **only to CoreTests dependencies**, not to production Core (no production dependency cycle). It requires fresh controlled Test Lab `--m1-fixtures`, including **AETHER Effect Disposable**. Against an active real engine, `.focus`, `.setFrame`, `.preview`, `.live`, `.effect(.wobble)` and `.effect(.dissolveClose)` all reject with **Stop Kinetiq**; passive `.refresh` succeeds and fixture frame/on-screen state stays unchanged. No global input injection or native fixture mutation is intended by this interlock test; it does not automate drag/close or attest effect readiness.

Admission checks, including a recheck after awaiting configuration, are implemented in RuntimeModel; visible panels observe status every **500ms**, without autostart. This is not a cross-process IPC lock or unconditional mutual exclusion: independently starting an engine during already-in-flight AETHER work is not atomically prevented. Finish/cancel that work before any external start.

### Current line coverage — explicit compatible merge

The default profile and then live/effects/capture/native profiles were saved **before each next run**, with compiled source unchanged and compatible instrumentation: `/tmp/aether-kinetiq-final-{default,live,effects,capture,native}.profdata`. All five were explicitly merged with `llvm-profdata merge -sparse` into the package binary directory's `codecov/default.profdata`, then reported by `Scripts/coverage.sh`.

| Source | Line coverage |
|---|---:|
| WindowSnapshotLease | 95.20% |
| CaptureStreamLease | 94.95% |
| ScreenCaptureCoordinator | 92.86% |
| WindowPreviewCoordinator | 94.12% |
| WindowEffectCoordinator | 94.92% |
| WobbleSimulation | 100% |
| MetalOverlayPresenter | 90.75% |
| WindowAccessibilitySession | 89.42% |
| KinetiqEngineCoordinator | 85.55% |
| TOTAL | **64.48% — 4,491 lines, 1,595 uncovered** |

The linked test coverage perimeter now includes Interface/Effects through the new test dependency. TOTAL is **not a like-for-like coverage decrease from 1.0.7**. These are source-line metrics, not all-branch, Metal-shader, physical scanout or effect-readiness coverage.

## Updated external-engine boundary and historical reference

The local `/Users/lorenzov/dev/Wobbly` project is **Kinetiq**, GPL-3.0-or-later. The updated contract uses its **actual external app**, including authorized optional private `_AXUIElementGetWindow`, off-screen parking and event-tap/click replay; capture can prefetch/recapture on raise. **No source/assets/binary are copied into AETHER targets/distribution**. Retain original LICENSE/NOTICE/third-party notices and CC-BY texture attribution; no unilateral AETHER relicensing, separate-process legal exemption or general GPL incompatibility is asserted. Historical 1.0.7 reference-only comparisons stay historical.

The Kinetiq automated suite covers passive metadata/consent/pre-cancel, explicit launch/connect/graceful exit and real RuntimeModel admission rejection/passive refresh; it does not automate Manual K or certify event-tap/shader readiness, physical effects or restoration. See `KINETIQ_ENGINE.md` for the complete lifecycle and trust contract.

See `API_CONTRACTS.md`, `ROADMAP.md`, `EFFECTS_CATALOG.md` and the historical `M2_VALIDATION.md` for contracts and remaining acceptance boundaries.