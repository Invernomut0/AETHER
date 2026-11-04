# AETHERCore

Application orchestration, event bus and M0 bootstrap lifecycle.

`AetherCoordinator` loads a `ConfigurationRepository` before becoming ready. Start/stop are idempotent; stop invalidates an in-flight start, and cancellation or a load failure never marks bootstrap ready. It does not initialize capture or rendering. `AetherLog` provides privacy-conscious unified logging categories for lifecycle, configuration and permissions.

`PermissionCoordinator` is MainActor-isolated and conforms to `PermissionChecking`. Checks are passive; only explicit request methods may display a system prompt. ScreenCaptureKit still validates actual capture capability when M2 is implemented.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
