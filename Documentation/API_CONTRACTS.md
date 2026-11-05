# API Contracts

Public module interfaces are declared in Swift protocols and public value types. This document describes the cross-module contracts.

## Window discovery/control
Discovery produces snapshots with capabilities. Control methods must verify results and return typed failures. Discovery must not imply control capability.

## Capture
Capture is owned by the capture actor. Consumers receive immutable frame metadata and copied BGRA `Data` (at most 1600px per edge), never SDK objects. `captureSnapshot(request:)` takes one image through Apple's public [SCScreenshotManager](https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager) `captureImage` API; it creates no `SCStream` and has no screenshot refresh loop. `startCapture(request:)` explicitly selects continuous stream delivery. Both require a validated runtime handle and caller revalidation before/after asynchronous capture.

The concrete owner admits **one mutually exclusive snapshot or stream lease**, including startup and unconfirmed cleanup. Concurrent capture rejects additional ownership. Screenshot waiting has a 5s deadline; cleanup has an independent 3s deadline that does not inherit caller cancellation. Stop settles the Swift waiter, not the non-cancellable SDK enumeration/image callbacks: callback ownership and resources remain retained until actual completion, even after timeout. Unconfirmed cleanup blocks replacement until retry confirms release. On success, screenshot SDK inputs and the snapshot lease are released before the copied frame reaches static Metal presentation.

For live streams, Stop likewise settles pending startup and independently awaits confirmed SDK teardown; Start rechecks ownership/activity after suspension. These contracts do not guarantee that SDK callbacks return. Tests observe internal session IDs without exposing SDK objects, titles or pixels. Screen Recording remains required in both modes; no private flags, indicator suppression or permission bypass is used, and absence of macOS indicators is not guaranteed.

## Diagnostic preview
`WindowPreviewCoordinator.preview(..., mode: .snapshot)` is the default. **Snapshot 5s** presents one captured image: receipt-age freshness is checked only before its first presentation (at most 1s old). Its retained texture is intentionally static for at most 5s, not a source of refreshed content; existing permission/secure-input and native identity/geometry monitors remain active. **Live diagnostic** explicitly uses continuous 30fps `SCStream` delivery, with OS recording indicators expected. Live still requires its first complete frame within 2s and checks freshness for every handoff. Both preserve the native window and remove the overlay on interruption/cancellation.

For a successful snapshot, `framesPresented == 1` means one GPU-completed submission, not physical scanout or proof that the displayed content stayed fresh. GPU resources remain owned until actual command completion even after the 750ms presentation deadline. Neither mode certifies physical platform behavior or implements M3 animation.

Both modes check passive Recording/secure-input state and `CGWindowListCopyWindowInfo(.optionIncludingWindow)` every 100ms. Visibility requires exactly one row matching the original CG ID, PID and `isOnScreen == true`, checked before AX IPC; this does not replace runtime-handle generation or AX geometry validation. Callers validate after asynchronous capture/before presentation, so the monitor schedules its next AX validation 500ms after monitor start rather than immediately duplicating that query, then continues every 500ms plus bounded AX latency. This combination fixes the observed immediate post-GPU AX/minimization race; the earlier CG-only guard attempt still timed out. Timeouts are not accepted as native interruption, budgets were not increased and SDK delays were not injected. Focused move/minimize and three complete post-fix suites passed; exact evidence and remaining platform checks are in `M2_VALIDATION.md`.

## Rendering
Render commands are values. GPU objects remain owned by the renderer. Renderer initialization, suspension and shutdown are explicit lifecycle operations.

## Effects
Effects declare ID, category, triggers, parameter schema, capture/3D requirements and performance class. Unknown effect IDs fail validation.

## Animation
Timeline times are monotonic offsets in seconds. Progress is clamped. Cancellation must invoke cleanup. Completion behavior is explicit.

## Persistence
All writes are transactional. Migrations are numbered, tested and backed up before destructive schema changes.
