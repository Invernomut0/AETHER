# Kinetiq External Engine — Experimental Contract

## Authorization and current status

On **5 November 2026**, the user explicitly requested the actual Kinetiq engine and authorized private techniques and off-screen windows. This updates the former reference-only development boundary: **private AX mapping, global event taps/click replay and temporary off-screen native-window parking are permitted in an explicitly opted-in experimental path**. They remain disabled by default in AETHER and are not dependencies of its public stable path. Authorization is not M2 physical/platform, full M3/M4, Living Window Gate 0 or release acceptance.

Status: **1.0.8/build 9 locally validated**. Receipts verify helper/build, actual RuntimeModel admission/lifecycle tests, default/live regressions, compatible coverage, both built versions, all four active-engine helper guards, selected-engine normal exit and exact local app relaunch/Quick Look/Finder refresh. Previously published 1.0.7/build 8 results stay historical. Git commit/origin verification is tracked in `TODO.md`, separately from remote CI and manual acceptance.

## Actual engine, not an imitation

- Local upstream checkout: `/Users/lorenzov/dev/Wobbly`; project/app name **Kinetiq**. Integration source reference supplied by the main workflow: HEAD `0e1b2a2d22cf77b74bdc595d40c79f842e3af807` (not a cryptographic authenticity claim).
- Actual built `/Users/lorenzov/dev/Wobbly/build/Kinetiq.app`: `io.github.invernomut0.Kinetiq`, executable `Kinetiq`, **0.1.27/build 28**, including `Kinetiq_KinetiqEffects.bundle`. Actual vtool verification confirms both Mach-O arm64/x86_64 slices have **`LC_BUILD_VERSION minos 14.0`**; this is deployment metadata, not macOS 14 runtime certification.
- `KinetiqEngineCoordinator` uses `NSWorkspace` to launch/connect to that separately installed real app and `NSRunningApplication` for normal termination. Kinetiq's own physics model, shaders, overlays and input/capture integration execute in **its process**. There is no linked Kinetiq library, code/asset vendoring, helper pretending to be the engine, readiness IPC or effects/settings RPC.
- `KinetiqEnginePanel` is wired into **Effects**. AETHER's original `WindowEffectCoordinator` Wobble 2s/Close with dissolve remains a **separate public-API diagnostic fallback**, not the requested engine and not an implementation of Kinetiq drag/close behavior. Its one-shot snapshot, duration and Reduce Motion contracts do not describe Kinetiq.

## Build and selection

Validated `bash Scripts/build-kinetiq.sh [sourcecheckout]` defaults to sibling `Wobbly`, validates checkout identity/resources/licensing, refuses rebuilding a running engine and delegates to original upstream `scripts/build-app.sh`. `/tmp/aether-kinetiq-engine-build.log` exited 0; upstream source remained unchanged and clean at the HEAD above. Default `SIGN_IDENTITY=-` selects local ad-hoc signing, not Developer ID/notarization or persistent TCC grants. Actual original `swift test --package-path /Users/lorenzov/dev/Wobbly` passed **74/74**, no failures (`/tmp/aether-kinetiq-upstream-tests.log`, exit 0). Preserve upstream Swift 5 concurrency and deprecated x86 SDK warnings; AETHER's Swift 6 build pass does not make Kinetiq Swift 6.

The resulting app stays at `<sourcecheckout>/build/Kinetiq.app`; it is **not embedded in AETHER.app or included as an AETHER-distributed binary**. Select that trusted bundle in Effects. Discovery also suggests `~/Applications/Kinetiq.app` and `/Applications/Kinetiq.app`; a suggestion/validation never executes it. Rebuilding/signing may require manually regranting access.

Validation resolves canonical paths and checks the .app directory, expected bundle ID/executable/package type, nonempty version/build, executable containment/executability and nonempty packaged effects resources. It does **not** validate the signature, prove shader correctness or authenticate who produced the bundle. Select only a trusted local build.

## Lifecycle contract

| Operation | Contract / limits |
|---|---|
| Construction, selection, Refresh | Passive metadata/process inspection; no launch, permission grant or automatic takeover |
| Start / Connect | Requires risk checkbox plus valid trusted selected bundle. One exact matching existing instance may be connected; multiple/conflicting installations are rejected |
| Launch | Explicit `NSWorkspace.openApplication`, no activation request, app substitution disabled; 10-second confirmation wait |
| Cancel wait / timeout | Ends waiting, **cannot revoke** the issued Launch Services request; pending token and callback ownership remain, blocking replacement; a late matching handle is retained |
| Running | Means process existence only, **not** permission/event-tap/shader/effect readiness; no readiness protocol exists |
| Stop Kinetiq | Waits for pending launch/normal termination within a 10-second operation deadline; validates selected bundle/executable identity before `terminate()`; never force-kills |
| Refused/timed-out/cancelled Stop | Retains uncertain ownership/handle so Refresh/retry or manual wave-menu quit remains possible; does not certify restoration |
| Effects page close / AETHER exit | Does not stop the independent engine. A structured page task can stop waiting, but an issued OS launch/quit may complete later |

RuntimeModel admission blocks **AETHER focus/move/capture/effect commands** while Kinetiq is starting, stopping, running or unresolved, including manually launched instances. It rechecks after awaiting configuration; visible panels observe status every **500ms**, without autostart. Actual runtime rejection/passive discovery passed the lifecycle test below. This is **not a cross-process IPC lock**: an independent external start during already-in-flight AETHER work is not atomically prevented. Finish/cancel AETHER operations/overlays before any external launch; do not infer unconditional mutual exclusion or tested late/refused-quit timing.

## Permissions, settings and capture

Kinetiq has its **own** Accessibility and Screen Recording permission identity. AETHER grants do not transfer. Explicit launch can show Kinetiq's prompts; the user grants access in System Settings and restarts Kinetiq if required. Do not auto-allow prompts, edit TCC, autostart either capture or Kinetiq, or bypass recording indicators.

Kinetiq uses private `_AXUIElementGetWindow` window mapping, global event taps and click replay for supported interactions, and parks native windows temporarily off-screen. This is not a universal OS lifecycle-interception API. Its `captureSampleBuffer` path can prefetch or recapture on window raise; **not strictly one image per gesture**. Its own physics/shaders are used, not AETHER's preview lattice.

AETHER's snapshot limits, timeout/resource budgets, credential exclusions, `captureExcludedBundleIDs`, `effectsEnabled` and system/config Reduce Motion handling **do not automatically apply to Kinetiq**. Its own settings govern behavior; there is no settings synchronization. Inspect upstream settings/exclusions and real indicators rather than inferring privacy or motion compliance from AETHER's dashboard. Indicator absence is never guaranteed.

### Enable effects in the real app

1. Save work and finish/cancel AETHER operations/overlays, also before an independent external launch. Use an unlocked desktop and disposable Test Lab windows first. In AETHER → **Effects**, choose trusted Kinetiq.app, read warnings, check experimental consent, then **Start / Connect Kinetiq**. AETHER bootstrap/selection/Refresh are passive; this explicit command may launch and show Kinetiq's own prompts.
2. Resolve Kinetiq's own permission prompts manually. Open its **wave icon** in the macOS menu bar; confirm **Kinetiq Enabled** and **Drag from Title Bar**. Title-bar dragging and the upstream tilt/glide settings default enabled, but existing saved preferences may differ. Do not reset user settings silently.
3. Open **Setup…**, explicitly choose a **Close** effect, for example **Fire**. A nil close-effect selection means **Off**; a fresh installation is not proof that a close shader is selected. AETHER cannot choose it via RPC.
4. Open **AETHER Test Lab** manually. Drag a disposable window by the title bar; close only an empty disposable. Verify real geometry/input, effects and indicators before/during/after. Do not run AETHER diagnostic effects at the same time.
5. Use **Stop Kinetiq** or wave menu → **Quit Kinetiq**. Inspect the native windows, position, focus/input and overlays after termination. A stopped PID is not evidence that every window was restored.

## Cleanup and experimental risks

Native windows stay authoritative even during parking; an off-screen window is not a closed one. Normal upstream termination invokes `cancelAll` and synchronous AX-restoration attempts. This is an intended cleanup path, **not proof** of complete restoration. Crashes, AX denial/refusal, OS changes, display removal, Spaces/full-screen transitions or failed cleanup can leave windows displaced or overlays/input in an uncertain state.

If Stop fails, preserve diagnostics and inspect the wave menu/native application. Retry normal Stop or normal Quit; never automatically kill a potentially parking engine. Do not blindly replay a close or restore stale coordinates over user changes. No blanket crash-recovery guarantee is provided. Kinetiq remains running after AETHER quits until separately stopped.

## Licensing and distribution boundary

Kinetiq remains **GPL-3.0-or-later** in its original checkout. Retain its `LICENSE`, `NOTICE`, original authorship and third-party notices, including Compiz-derived model/resize work, Burn-My-Windows shader notices and third-party MIT notices. Upstream texture images carry **CC-BY-4.0** attribution; retain it with the original project/assets. Do not copy its sources, shaders, textures or binary into AETHER targets/bundles in this integration.

AETHER's `LICENSE` is currently a development/evaluation placeholder; this task does not change it or unilaterally relicense the repository. Process separation describes this implementation, **not a legal exemption** from licensing obligations and not a general claim that GPL is incompatible. Any future redistribution, bundling or code reuse requires an explicit licensing/distribution review with applicable source, license and attribution obligations preserved. This bridge does not make AETHER distribution-ready.

## Verified local validation and remaining acceptance

`KinetiqEngineTests` passed **7/7 XCTest**, zero skips, **1.595s** in `/tmp/aether-kinetiq-final-live.log` (exit 0): six passive tests and one opt-in lifecycle test. Passive cases reject real Terminal.app, inspect the real Kinetiq bundle/canonical paths, require consent and exercise pre-cancelled start/stop and invalid-bundle no-launch behavior. Missing bundles can skip future checks; do not confuse skips with passes.

`AETHER_RUN_KINETIQ_INTEGRATION=1` requires fresh controlled Test Lab `--m1-fixtures`, including **AETHER Effect Disposable**. The test verifies real launch/same-PID connect, independent manager discovery without takeover, refused consent to connect an existing instance, and the actual `AetherRuntimeModel` via `@testable AETHERInterface`. Interface is added **only to CoreTests dependencies**, not production Core (no production cycle). Active `.focus`, `.setFrame`, `.preview`, `.live`, `.effect(.wobble)` and `.effect(.dissolveClose)` all reject **Stop Kinetiq**; `.refresh` succeeds and fixture frame/on-screen state stays unchanged. Normal Stop exits. No global input injection/native mutation is intended by this test. It can show Kinetiq's own prompts, skips rather than manages a user's pre-existing engine and attempts normal teardown after failure. It does **not** automate dragging, click replay, red-button close/effect selection or prove readiness/restoration. Arbitrary late/pending launch and refused/timed-out quit timing remains manual/source-contract review; no forced SDK delays were injected.

Final AETHER default validation passes **53 functions / 58 cases**, with **34 skipped functions**; native/capture/effect receipts, both built **1.0.8/build 9** plists and fresh five-profile merged line coverage are in `VISUAL_EFFECTS_VALIDATION.md`. KinetiqEngineCoordinator line coverage is **85.55%**; total **64.48%** includes newly linked Interface/Effects and is not comparable like-for-like to 1.0.7. No branch/shader/readiness claim.

Final guard receipt (**5 November, approximately 12:45**): `Scripts/build-kinetiq.sh`, `Scripts/test-effect-integration.sh`, `Scripts/test-capture-integration.sh` and `Scripts/test-window-integration.sh` were each invoked with real Kinetiq running from the exact trusted bundle above. All returned **exit 2** with explicit quit/stop Kinetiq messages before any operation started; enclosing check **`HELPER_GUARDS_EXIT0`**. All four shell syntax checks passed. The identity-checked selected `NSRunningApplication` then exited after normal `terminate()`, with actual exit confirmed and no forced kill; this is not native-restoration evidence.

The exact local AETHER/Test Lab bundles finished NSWorkspace launch as **PIDs 69118 / 69116**, Lab with `--m1-fixtures`; CG-owned **AETHER Effect Disposable** and **AETHER Refuses Close** were verified, **`KINETIQ_RUNNING=false`**. Quick Look reset/cache reset, Finder Debug-directory update and clean `git diff --check` were recorded. Manual real drag/close, indicators, Reduce Motion/exclusions, focus/input, cancellation/normal quit behavior, restoration and physical platform checks remain **Review**. Full M2/M3/M4, Living Window and release acceptance remain unaccepted.