# Acceptance Criteria

## Functional
- Window discovery refreshes and reports supported descriptors.
- Window control verifies actual post-operation geometry.
- Unsupported AX attributes fail with typed errors and do not crash.
- Capture starts only after permission and a valid shareable window are available.
- Overlay is temporary and always has a cleanup path.
- Effects are discoverable through the registry.
- Animation sequences can be cancelled.
- Layout trees validate uniqueness and constraints.
- Presets survive app restart and schema migration.
- Permission revocation degrades gracefully.
- Multi-display coordinate mapping is tested.

## Performance targets (targets, not measured claims)
- 60 FPS baseline for supported effects on reference Apple Silicon hardware.
- Up to 120 FPS when display and workload permit.
- No continuous idle render loop when no animated content exists.
- Base app memory target under 250 MB before large captures/effect workloads.
- Input-to-visible-animation target under 50 ms in controlled test scenarios.
- Bounded capture queues; stale frames dropped.
- Zero known orphan overlays or unreleased capture sessions.

## Reliability
- 2-hour soak test.
- 1,000 effect transitions.
- 100 open/close or AETHER-controlled transition cycles.
- 50 display topology changes.
- 20 sleep/wake cycles.
- Permission revoke/regrant tests.
- App crash/relaunch recovery test.

## Definition of Done
Code builds; tests pass; feature is integrated; failure paths and fallback are implemented; diagnostics are present; documentation is updated; no placeholder is represented as complete.
