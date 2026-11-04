# AETHERWindowManager

Window discovery, Accessibility control, display topology and geometry. M1's local integration gate is recorded in `Documentation/M1_VALIDATION.md`.

`NativeWindowService` is a MainActor facade and composes discovery/control over one `WindowAccessibilitySession` actor. AppKit process metadata stays on MainActor. AX elements never escape their owning actor; consumers get Sendable descriptors and session handles. The compatibility discovery/controller adapters use a shared service by default; explicitly injected instances must share the same service to share generations.

CG enumeration includes normal-layer on/off-screen rows exposed by the window server. Correlation requires mutually unique PID/geometry matches; optional nonempty titles must agree. No private AX window-ID API or first-window fallback is used. Missing launch identity, permission, AX frame or unique mapping means no control handle. `canCapture` remains false until the capture milestone can establish that capability.

Every command validates the generation, process launch date, current AX membership and current CG correlation. The facade rejects overlapping commands for the same window across suspension points. Disappearance/ambiguity/revocation invalidates entries. Successful refresh drops entries not matched; cancellation/failure clears the registry. AX IPC timeout is 150 ms per call; discovery has a five-second AX budget and degrades unavailable apps to read-only. Geometry has a three-second deadline; raise and focus verification each have two seconds. OS enumeration/activation calls are synchronous system APIs and not preemptible by Swift task cancellation.

Geometry uses global top-left points. Position is applied before growing to avoid display-edge clamping, size is allowed to settle, and position is reapplied. Success needs both AX and CG frames to agree across observations. Partial failures invalidate the handle and report requested/observed geometry without a blind rollback. Focus raises the selected AX element, selects it as main, activates its application and verifies that exact element is focused.

Limitations: refresh is explicit (no AXObserver lifecycle feed yet); identical/underdetermined windows remain read-only; hidden/minimized windows missing from the CG inventory cannot be controlled; unknown minimized state defaults to false. Multi-display conversion is implemented but physical multi-display certification, permission-revocation stress and minimum-OS runtime checks remain outstanding. Native windows stay authoritative; no capture or overlay is created here.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
