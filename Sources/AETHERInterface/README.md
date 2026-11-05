# AETHERInterface

SwiftUI dashboard, settings and diagnostics. The M0 overview owns bootstrap/permission diagnostics; the M1 Windows panel shows actual native snapshots with search, read-only filtering, capability labels and Focus/Center/Left half commands. **Effects** now hosts `KinetiqEnginePanel`; other unimplemented destinations remain explicitly scaffolded.

Status **1.0.8/build 9 locally validated**: real external Kinetiq's optional private mapping/input replay/parking stays disabled by default in AETHER. Default/build/both actual built versions and runtime admission/lifecycle results are verified, as are all four active-engine exit-2 helper guards, selected-engine identity-checked normal exit and exact local app relaunch/Quick Look/Finder refresh. Final AETHER/Test Lab PIDs **69118 / 69116** (`--m1-fixtures`), both controlled effect/refusal titles and **`KINETIQ_RUNNING=false`** were verified; no visual/restoration acceptance is inferred. Full M2/M3/M4/Living Window gates are not accepted. Git publication receipts are tracked in `TODO.md`, independently of remote CI Review.

## Effects → Kinetiq (actual external app)

`KinetiqEnginePanel` offers trusted local app selection, an explicit experimental-risk checkbox, **Start / Connect Kinetiq**, **Stop Kinetiq**, **Cancel wait** and passive **Refresh**. Metadata/resource validation is not authentication. Selection/startup do not launch anything; only explicit consented Start/Connect does, potentially showing Kinetiq's own AX/Recording prompts. AETHER grants do not transfer.

Status is **Process running · readiness unknown**, not effect success. AETHER has no readiness/settings RPC: guide the user to the real **wave menu → Kinetiq Enabled / Drag from Title Bar → Setup… → Close → Fire** (or their chosen effect). Nil Close selection means Off; saved preferences can differ from defaults. Do not display fake integrated controls or substitute AETHER's preview lattice/shader for Kinetiq.

Warn before enabling: save work/use disposable windows, private API/parking failures can leave native windows displaced, indicators are not suppressed and restoration is not guaranteed. Kinetiq's own capture/exclusion/physics/motion settings apply; AETHER Reduce Motion/budgets do not transfer. It continues after page dismissal/AETHER quit; Stop or its wave-menu Quit requests normal termination only. Start/Stop wait 10 seconds; cancelling a wait cannot revoke the OS request. Retained late/pending ownership blocks replacement; no forced kill.

Actual RuntimeModel admission rejects `.focus`, `.setFrame`, `.preview`, `.live`, `.effect(.wobble)` and `.effect(.dissolveClose)` with **Stop Kinetiq** while active/pending, including independent instances; passive `.refresh` succeeds, fixture frame/on-screen state unchanged. It rechecks after configuration await; panels observe every **500ms while visible**, no autostart. Actual-model `@testable AETHERInterface` lifecycle tests pass **7/7 XCTest**, zero skips, **1.595s**, fresh Lab `--m1-fixtures`/Effect Disposable; dependency is **CoreTests-only**, no production Core cycle. **Not a cross-process IPC lock**: an independent external start during already-in-flight work is not atomically prevented. Finish/cancel native diagnostics before launch. No global input injection/native fixture mutation intended; readiness and arbitrary late/refused-quit timing remain outside test proof. See `Documentation/KINETIQ_ENGINE.md` and visual validation.

## Windows → separate public-API diagnostic fallback

The controls below are not Kinetiq and must run only with it stopped.

`AetherRuntimeModel` composes the native service without exposing AX references. The Windows panel uses a structured `.task(id:)`; replacing/dismissing it cancels the command. During an operation controls are disabled and progress is visible. Errors/cancellation clear stale UI snapshots and require refresh. Center/Left half target the selected screen's visible frame in global CG points. Startup and listing never prompt for permission or capture content.

Current M2 preview UX behavior:

- Startup does not begin capture.
- **Windows → Snapshot 5s** is the default, explicit one-shot preview with intentionally static content; **Live diagnostic** explicitly selects continuous streaming with expected OS recording indicators.
- **Stop overlay** and Escape while the Windows panel has focus cancel the transaction; Escape is not a global hook.
- Task cancellation on dismissal is explicit and cleanup-oriented.
- Both preview modes require Screen Recording; preview controls are disabled when it is not granted.
- Permission requests remain explicit user actions; no implicit prompt is issued during normal startup/listing.

Preview is intentionally temporary and non-interactive. It does not replace/hide native windows in this milestone.

Explicit effect controls:
- **Wobble 2s** animates one captured/uploaded snapshot over the still-visible/interactive original with an independent 17 × 13 fixed-120Hz lattice. Native movement interrupts without rollback; no global native-drag hook.
- **Close with dissolve…** shows a destructive confirmation with Cancel. Confirming sends one actual native AX close only after hidden capture/upload preflight, requires full CG disappearance including off-screen rows within a 2s verification deadline, then shows an original 1.1s dissolve. `canClose` is a request capability, not guaranteed acceptance. Refusal/save dialogs/unconfirmed outcomes are errors, never permission to pretend closure; no automatic retry.
- **Stop overlay**, Escape and leaving/replacing the structured task cancel/remove AETHER preview/effect visuals, **not Kinetiq**. **They cannot undo a native close.** Panels cannot become key/main or intercept input. This public diagnostic coordinator performs no universal red-button/Cmd-W interception or native hiding/off-screen parking; external experimental Kinetiq is separate.
- System OR config Reduce Motion uses a fade; maximum animation duration 3s, 60fps target pacing (not measured fps), cached texture and one in-flight GPU command with 750ms wait/actual callback lifetime.

The panel guide asks users to filter **AETHER Test Lab**, observe target title/macOS menu bar BEFORE/DURING/AFTER **Snapshot 5s**, and use Live only as an optional continuous positive control. Indicators can persist as recent use; record **visible / not visible / not determined**, currently user-pending. One-shot capture cannot guarantee absent indicators; there is no suppression/bypass/private flag.

For manual Wobble/Close use **AETHER Effect Disposable only**, with no unsaved real content; Test Lab's **Open Effect Disposable** allows reopen/repeat after refresh. **AETHER Refuses Close** is a real `windowShouldClose == false` automated fixture, not a manual destructive-demo target. The new effect helper uses `AETHER_RUN_EFFECT_INTEGRATION=1`; existing native-close coverage uses `AETHER_RUN_WINDOW_INTEGRATION=1`, sequential fresh-fixture suites.

See `Documentation/API_CONTRACTS.md` for freshness/cleanup and `Documentation/VISUAL_EFFECTS_VALIDATION.md` for verified local receipts, expanded Interface/Effects coverage perimeter and pending manual steps. Current effects **6 functions / 7 cases**, capture **22 functions / 26 cases** with two denial skips and native **17/17** pass; historical 1.0.7 remains historical. No physical effects/indicator/restoration acceptance follows from those tests.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
