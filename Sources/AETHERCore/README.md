# AETHERCore

Application orchestration, event bus and preview transaction lifecycle.

`AetherCoordinator` loads a `ConfigurationRepository` before becoming ready. Start/stop are idempotent; stop invalidates an in-flight start, and cancellation or a load failure never marks bootstrap ready. It does not initialize capture or rendering. `AetherLog` provides privacy-conscious unified logging categories for lifecycle, configuration and permissions.

`PermissionCoordinator` is MainActor-isolated and conforms to `PermissionChecking`. Checks are passive; only explicit request methods may display a system prompt. ScreenCaptureKit validates actual capture capability for both preview modes.

`WindowPreviewCoordinator` owns the Core-level preview transaction contract:
- `.snapshot` is the default: one screenshot, no `SCStream` or refresh loop; successful capture ownership is released before static presentation.
- `.live` explicitly selects continuous diagnostic streaming. First-frame and per-handoff freshness checks apply to live delivery; snapshot freshness is checked only before first presentation.
- Both modes preserve native/permission monitoring, cancellation and confirmed cleanup. Unconfirmed capture cleanup blocks replacement in either mode.

Capture requires a validated `RuntimeWindowHandle`; ID-only capture start is intentionally unsupported. Callers must revalidate with `NativeWindowService.validatedWindow` before and after asynchronous capture. If cleanup fails, the next preview retries cleanup before admitting either capture mode. See `Documentation/API_CONTRACTS.md` for deadlines, monitor scheduling and SDK/GPU ownership rules.

Core orchestration does not mutate native windows during preview. If the target moves, resizes, minimizes, disappears, or fails identity revalidation, preview aborts and cleanup runs.

Screen Recording remains required in both modes; a one-shot API does not guarantee absent macOS indicators. Local validation does not certify full M2 platform behavior or implement M3 animation; see `Documentation/M2_VALIDATION.md`.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
