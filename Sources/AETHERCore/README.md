# AETHERCore

Application orchestration, event bus and preview/effect lifecycle. **1.0.8/build 9 locally validated**. Builds/tests/compatible coverage/both built versions, all four active-engine exit-2 helper guards (`HELPER_GUARDS_EXIT0`), selected-engine identity-checked normal exit and exact local app relaunch/Quick Look/Finder refresh are verified. No forced kill was used; exit is not restoration proof. Exact receipts: `Documentation/VISUAL_EFFECTS_VALIDATION.md`; Git publication tracking is separate from remote CI Review in `TODO.md`.

## Real external Kinetiq engine

`KinetiqEngineCoordinator` manages a **separate Kinetiq.app process**, not a linked/reimplemented engine. The updated 5 November contract authorizes its private AX mapping, event-tap/click replay and temporary off-screen parking only as an explicit-consent experiment, disabled by default in AETHER. Canonical bundle/executable/version/resource checks are metadata validation, not authentication. Constructor/discovery/Refresh are passive; Start/Connect requires consent and one matching trusted installation.

All AppKit/process state is MainActor-owned. Start/Stop waits are bounded to 10 seconds; cancellation/timeout cannot revoke issued OS requests. Pending launch ownership blocks replacement and late callback handles are retained. Stop revalidates the selected identity and requests normal `terminate()` only, never force-kill; uncertainty remains retryable. Independently launched instances contribute to `isActive` without automatic takeover. Process existence is not permission/event-tap/shader readiness; no IPC/settings RPC exists.

RuntimeModel admission blocks focus/move/capture/effects for active/pending/unresolved engines, including independent instances; passive discovery allowed, recheck after config await, 500ms visible-panel observation without autostart. Final **7/7 XCTest**, zero skips, **1.595s**, includes actual `AetherRuntimeModel` via `@testable AETHERInterface`: six Stop Kinetiq rejections, passive refresh/unchanged fixture geometry/visibility, same-PID connect, independent discovery without takeover, refused consent and normal exit. Interface is **CoreTests-only**, not production Core (no cycle). **Not a cross-process IPC lock**: independent launch during in-flight work is not atomically prevented; finish/cancel first. No input injection/native mutation intended, drag/close/readiness or arbitrary late/refused-quit timing proof. Kinetiq's own grants/settings/policies apply, survive AETHER exit and do not guarantee restoration. See `Documentation/KINETIQ_ENGINE.md`; manual effects/recovery remain Review.

## Separate public-API diagnostics

The coordinators below are AETHER-owned fallback diagnostics, **not the requested Kinetiq engine**. Do not run them concurrently with it.

`AetherCoordinator` loads a `ConfigurationRepository` before becoming ready. Start/stop are idempotent; stop invalidates an in-flight start, and cancellation or a load failure never marks bootstrap ready. It does not initialize capture or rendering. `AetherLog` provides privacy-conscious unified logging categories for lifecycle, configuration and permissions.

`PermissionCoordinator` is MainActor-isolated and conforms to `PermissionChecking`. Checks are passive; only explicit request methods may display a system prompt. ScreenCaptureKit validates actual capture capability for both preview modes.

`WindowPreviewCoordinator` owns the Core-level preview transaction contract:
- `.snapshot` is the default: one screenshot, no `SCStream` or refresh loop; successful capture ownership is released before static presentation.
- `.live` explicitly selects continuous diagnostic streaming. First-frame and per-handoff freshness checks apply to live delivery; snapshot freshness is checked only before first presentation.
- Both modes preserve native/permission monitoring, cancellation and confirmed cleanup. Unconfirmed capture cleanup blocks replacement in either mode.

Capture requires a validated `RuntimeWindowHandle`; ID-only capture start is intentionally unsupported. Callers must revalidate with `NativeWindowService.validatedWindow` before and after asynchronous capture. If cleanup fails, the next preview retries cleanup before admitting either capture mode. See `Documentation/API_CONTRACTS.md` for deadlines, monitor scheduling and SDK/GPU ownership rules.

Core orchestration does not mutate native windows during Snapshot/Live preview. If the target moves, resizes, minimizes, disappears, or fails identity revalidation, preview aborts and cleanup runs.

`WindowEffectCoordinator` separately implements two explicit manual actions:
- `.wobble` captures/uploads once, then deforms a cached snapshot with an independent 17 × 13 fixed-120Hz lattice for the UI's 2s action. Native original stays visible and interactive; native changes interrupt without rollback. This is not a global native-drag hook.
- `.dissolveClose` prepares hidden, requests one public AX close for the exact registered generation/PID and enabled button, waits for full CG disappearance including off-screen rows within a 2s verification deadline, then renders an original 1.1s procedural dissolve. Refusal/unconfirmed closure does not authorize animation or automatic retry; Stop cannot undo a real close. No native hiding or universal red-button/Cmd-W interception.

Effects reuse Capture's one-shot privacy/5s wait/independent 3s cleanup/callback ownership rules, not `SCStream`. Initial snapshot age is checked; close rejects stale post-close pixels without claiming rollback. One transaction per coordinator, maximum 3s animation, monotonic 60fps target pacing (not measured fps), system OR config Reduce Motion fade. Reported frames are GPU completions, not scanout. `removeOverlay()` removes visuals and requests stop; the owning structured task is also cancelled by UI Stop/Escape/navigation. GPU resources live until callback even if its 750ms control-flow wait expires.

Current diagnostic effects pass **6 functions / 7 cases**, zero skips, **9.880s**; capture **22 functions / 26 cases**, two denial skips, **21.408s**, sequential fresh controlled fixtures with Kinetiq stopped. Final compatible merged line coverage: preview **94.12%**, effect coordinator **94.92%**, Kinetiq coordinator **85.55%**. Expanded Interface/Effects linkage means TOTAL is not like-for-like with historical 1.0.7, nor branch/shader coverage. Neither tests nor the updated contract accept full M2/M3/M4/Living Window. Recording remains required independently per app, indicators user-pending/no absence guarantee. Exact logs/profiles/manual protocols in visual validation. Effect opt-in remains `AETHER_RUN_EFFECT_INTEGRATION=1`; external `AETHER_RUN_KINETIQ_INTEGRATION=1` does not automate Kinetiq effects.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
