# AETHERCore

Application orchestration, event bus and preview transaction lifecycle.

`AetherCoordinator` loads a `ConfigurationRepository` before becoming ready. Start/stop are idempotent; stop invalidates an in-flight start, and cancellation or a load failure never marks bootstrap ready. It does not initialize capture or rendering. `AetherLog` provides privacy-conscious unified logging categories for lifecycle, configuration and permissions.

`PermissionCoordinator` is MainActor-isolated and conforms to `PermissionChecking`. Checks are passive; only explicit request methods may display a system prompt. ScreenCaptureKit still validates actual capture capability when M2 is implemented.

`WindowPreviewCoordinator` owns the Core-level preview transaction contract:
- Preview duration is capped at 5 seconds.
- The first complete frame must arrive within 2 seconds.
- Handoff frames older than 1 second are dropped/aborted.
- Permission and secure-input state are monitored at 100ms cadence.
- Window identity/frame are revalidated at 500ms cadence with bounded AX latency.

Capture start requires a validated `RuntimeWindowHandle`; ID-only capture start is intentionally unsupported. Callers must revalidate with `NativeWindowService.validatedWindow` before and after capture start. If stop cleanup fails, the next preview retries `stopAll` before opening a new stream.

Core orchestration does not mutate native windows during preview. If the target moves, resizes, minimizes, disappears, or fails identity revalidation, preview aborts and cleanup runs.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
