# ADR 0002: Public API Baseline

Status: Accepted

Stable product behavior uses public Apple APIs. Experimental techniques are isolated and optional. No private API is a release dependency.

Consequences:
- Some system lifecycle effects cannot be universally replaced.
- Spaces manipulation is limited to supported public behavior.
- Capability detection and fallback are first-class features.
