# Data Models

Canonical model definitions are in `Sources/AETHERShared/Models`.

Rules:
- Runtime IDs are not persistent identities.
- Persist only stable configuration, not transient native window IDs.
- Use Codable versioned DTOs at persistence boundaries.
- Use typed identifiers in module APIs.
- Geometry serialization uses explicit Double-based DTOs to avoid platform-specific Codable assumptions.
- Unknown future enum values must be handled safely at import boundaries.
