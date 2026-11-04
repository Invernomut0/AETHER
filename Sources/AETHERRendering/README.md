# AETHERRendering

Metal device ownership, overlay presentation, and GPU command lifecycle.

Current preview renderer behavior (M2 first implementation):

- Overlay is created/presented on MainActor as a non-activating, non-interactive panel.
- Panel level is `normal` and ordering is relative to the selected native window.
- Geometry uses display-point coordinates with correct backing-scale handling.
- Overlay drawable size is bounded to a max edge of `3200` px.

GPU execution policy:

- Submission is serialized (one in-flight command at a time).
- Command completion has a 750ms timeout for control flow.
- Resources are retained until actual GPU completion, even when timeout paths trigger fallback cleanup.
- Remove is immediate and idempotent.

Diagnostics caveats:

- `framesPresented` currently counts GPU command completion, not guaranteed on-screen presentation.
- `allocatedTextureBytes` is an estimate and not a full-device allocation metric.

Scope caveat:

- Preview currently does not animate or replace/hide the native window; that transition behavior is planned for M3.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
