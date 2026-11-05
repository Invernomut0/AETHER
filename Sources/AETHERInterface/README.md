# AETHERInterface

SwiftUI dashboard, settings and diagnostics. The M0 overview owns bootstrap/permission diagnostics; the M1 Windows panel shows actual native snapshots with search, read-only filtering, capability labels and Focus/Center/Left half commands. Other navigation destinations remain explicitly scaffolded.

`AetherRuntimeModel` composes the native service without exposing AX references. The Windows panel uses a structured `.task(id:)`; replacing/dismissing it cancels the command. During an operation controls are disabled and progress is visible. Errors/cancellation clear stale UI snapshots and require refresh. Center/Left half target the selected screen's visible frame in global CG points. Startup and listing never prompt for permission or capture content.

Current M2 preview UX behavior:

- Startup does not begin capture.
- **Windows → Snapshot 5s** is the default, explicit one-shot preview with intentionally static content; **Live diagnostic** explicitly selects continuous streaming with expected OS recording indicators.
- **Stop preview** and Escape cancel the transaction.
- Task cancellation on dismissal is explicit and cleanup-oriented.
- Both preview modes require Screen Recording; preview controls are disabled when it is not granted.
- Permission requests remain explicit user actions; no implicit prompt is issued during normal startup/listing.

Preview is intentionally temporary and non-interactive. It does not replace/hide native windows in this milestone.

See `Documentation/API_CONTRACTS.md` for snapshot/live freshness, monitoring and cleanup semantics. One-shot capture does not guarantee absent macOS indicators; full M2 platform acceptance and M3 animation remain pending.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
