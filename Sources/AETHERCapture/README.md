# AETHERCapture

ScreenCaptureKit session ownership and bounded frame delivery.

Current M2 implementation uses actor-owned, single-lease capture semantics:

- `ScreenCaptureCoordinator` owns one active queue lease at a time.
- Capture callbacks are consumed on a serial owner queue.
- Frame payloads are copied to immutable BGRA `Data` inside the callback path before handoff.
- Stream configuration is bounded for preview: queue depth `3`, newest-only async buffering (`1`), max edge `1600` px, `30fps`, no audio/cursor/shadows.

Lifecycle and cleanup policy:

- Start deadline: 5 seconds.
- Stop deadline: 3 seconds.
- Stop cleanup intentionally does not inherit caller cancellation, to prioritize deterministic teardown.
- If stop fails, the lease is retained and the next preview attempts cleanup (`stopAll`) before opening a new stream.
- Late callbacks are tolerated and finish cleanup on the owner queue.

Validation/identity policy:

- ID-only start is rejected as unsupported.
- `CaptureRequest` requires a validated `RuntimeWindowHandle`.
- Callers must revalidate via `NativeWindowService.validatedWindow` before and after start.

Privacy policy:

- Built-in exclusions cover known credential-manager bundle families.
- User-defined exclusions are read from `configuration.captureExcludedBundleIDs` (restart required after config edits).
- Secure-input and permission checks are enforced before capture use.

Implementation note: this module is integrated but M2 gate acceptance still requires a host run with explicit Screen Recording consent and confirmed live output-path evidence.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
