# API Contracts

Public module interfaces are declared in Swift protocols and public value types. This document describes the cross-module contracts.

## Window discovery/control
Discovery produces snapshots with capabilities. Control methods must verify results and return typed failures. Discovery must not imply control capability.

## Capture
Capture sessions are owned by the capture actor. Consumers receive immutable frame metadata and a safely managed pixel/texture handoff. A session is always stoppable and cancellation-aware.

## Rendering
Render commands are values. GPU objects remain owned by the renderer. Renderer initialization, suspension and shutdown are explicit lifecycle operations.

## Effects
Effects declare ID, category, triggers, parameter schema, capture/3D requirements and performance class. Unknown effect IDs fail validation.

## Animation
Timeline times are monotonic offsets in seconds. Progress is clamped. Cancellation must invoke cleanup. Completion behavior is explicit.

## Persistence
All writes are transactional. Migrations are numbered, tested and backed up before destructive schema changes.
