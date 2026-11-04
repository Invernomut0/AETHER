# ADR 0001: Hybrid Native Window + Metal Overlay

Status: Accepted

AETHER keeps native application windows as the source of truth and uses temporary Metal overlays for visual transitions. This avoids pretending to replace WindowServer while enabling advanced visual effects.

Consequences:
- Capture/overlay lifecycle is a critical subsystem.
- Every effect needs native fallback.
- Overlay teardown and reconciliation are release blockers.
