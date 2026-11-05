# AETHERRendering

Metal device ownership, overlay presentation, and GPU command lifecycle.

Preview and explicit-effect renderer behavior (**1.0.8/build 9 locally validated**; physical/manual acceptance pending):

- Overlay is created/presented on MainActor as a non-activating, non-interactive panel.
- Panel cannot become key/main and ignores mouse input; it never replaces native interaction.
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

- Snapshot/Live diagnostic preview does not animate or replace/hide the native window.
- `prepareEffect(_:frame:relativeTo:)` validates/uploads once while the panel stays hidden (also hides any stale panel). `renderEffect(vertices:opacity:dissolve:)` reuses the cached texture with validated position/UV triangle values; no capture or per-frame texture upload. Prepared texture is released on remove/replacement/failure, while in-flight resources survive to the actual callback.
- Effect-only `relativeTo: 0` permits presentation after a separately confirmed native close; it is not a native identity or permission to close. Core alone authorizes the sequence; Rendering never sends AX actions. Ordinary preview requires a positive target number.
- Manual Wobble uses a bounded triangle mesh over the still-visible/interactive original; manual Close shows an original procedural dissolve **only after real native closure is confirmed**. System OR config Reduce Motion selects a fade. Duration maximum 3s and 60fps target pacing belong to Core, not a measured renderer performance guarantee.
- This **AETHER-owned renderer** adopts no global drag/close interception, native hiding/parking, indicator suppression or Kinetiq source/assets. Actual external Kinetiq is a separate explicitly authorized experimental process, not merely a reference or this renderer. Generic registry lifecycles remain no-op; these actions are not full catalog implementation.

Current `OverlayEffectTests` pass ABI/input, hidden preflight and real GPU/cache/focus checks; final real effects regression passes **6 functions / 7 cases**, zero skips, **9.880s**. Fresh compatible five-profile merge measures **MetalOverlayPresenter 90.75% source-line coverage**, not shader/physical scanout/input/indicator or achieved-fps certification. Expanded Interface/Effects linkage changes total coverage's perimeter; historical 1.0.7 stays historical. Physical/manual checks and full M2/M3/M4/Living Window gates remain open. Exact receipts: `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
