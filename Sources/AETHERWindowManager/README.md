# AETHERWindowManager

Window discovery, Accessibility control, display topology and geometry. M1's local integration gate is recorded in `Documentation/M1_VALIDATION.md`.

`NativeWindowService` is a MainActor facade and composes discovery/control over one `WindowAccessibilitySession` actor. AppKit process metadata stays on MainActor. AX elements never escape their owning actor; consumers get Sendable descriptors and session handles. The compatibility discovery/controller adapters use a shared service by default; explicitly injected instances must share the same service to share generations.

CG enumeration includes normal-layer on/off-screen rows exposed by the window server. Correlation requires mutually unique PID/geometry matches; optional nonempty titles must agree. No private AX window-ID API or first-window fallback is used. Missing launch identity, permission, AX frame or unique mapping means no control handle. `canCapture` remains false until the capture milestone can establish that capability.

Every command validates the generation, process launch date, current AX membership and current CG correlation. The facade rejects overlapping commands for the same window across suspension points. Disappearance/ambiguity/revocation invalidates entries. Successful refresh drops entries not matched; cancellation/failure clears the registry. AX IPC timeout is 150 ms per call; discovery has a five-second AX budget and degrades unavailable apps to read-only. Geometry has a three-second deadline; raise and focus verification each have two seconds. OS enumeration/activation calls are synchronous system APIs and not preemptible by Swift task cancellation.

Geometry uses global top-left points. Position is applied before growing to avoid display-edge clamping, size is allowed to settle, and position is reapplied. Success needs both AX and CG frames to agree across observations. Partial failures invalidate the handle and report requested/observed geometry without a blind rollback. Focus raises the selected AX element, selects it as main, activates its application and verifies that exact element is focused.

## Native close — 1.0.8/build 9 local regression passed

`WindowCapabilities.canClose` probes public `kAXCloseButtonAttribute`: the element must belong to the same PID, be enabled and advertise `kAXPressAction`. Its initializer and legacy Codable missing-field default are **false**; malformed field types still fail. Discovery is not a promise the app will accept closure.

`NativeWindowService.close(_:)` serializes same-window mutation, validates registered generation/process launch/AX membership/CG correlation, reacquires current process metadata and close-button capability, then attempts **one AXPress**. Final cancellation check immediately precedes the action with no intervening suspension. Preparation has a 2s budget and AX IPC remains bounded to 150ms per call; a separate **2s verification deadline** follows the irreversible request.

Success means exact ID/PID disappearance from a **full unfiltered CG inventory**, including off-screen windows. Missing geometry/visibility/layer is not disappearance; hidden/minimized/off-screen is not closed. Incomplete inventory or reused identity fails closed. `NativeWindowInventory` also supports the real ordered-out NSWindow regression.

- Before AXPress, cancellation sends no request.
- Once AXPress has been attempted, refusal/save-sheet, cancellation, timeout or verification failure produces **`NativeWindowCloseError.outcomeUnconfirmed(reason:)`**: close may still complete. No second press, automatic retry, native hiding or rollback is authorized.
- `isWindowClosed(_:)` requires this service's exact confirmed receipt (up to 128 retained), revalidates process launch identity and full CG membership, and rejects forged/unknown generation or reused PID/ID. Refresh revokes receipts when the native ID reappears.

Core's destructive effect prepares hidden and animates only after this close succeeds. **Stop removes the overlay but cannot undo native close.** This module requires AX, not Screen Recording; the capture/effect path separately requires recording consent. No universal red-button/Cmd-W interception or private AX-to-ID mapping is used.

Native-close integration uses **`AETHER_RUN_WINDOW_INTEGRATION=1`**, not a separate variable; effects use `AETHER_RUN_EFFECT_INTEGRATION=1`. Both consume **AETHER Effect Disposable**; run native/capture/effects sequentially with fresh fixtures and Kinetiq stopped. Current main-workflow `/tmp/aether-kinetiq-final-native.log` passes **17/17**, zero skips, **3.877s**, exit 0. Fresh merged **WindowAccessibilitySession line coverage 89.42%**; actual refusal/no-animation tests pass in separate effects regression, not every post-press cancellation/failure timing. Historical M1/1.0.7 stays historical. Neither tests nor the slice accept full M2/M3/M4/platform gates; receipts/manual review are in `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

Limitations: refresh is explicit (no AXObserver lifecycle feed yet); identical/underdetermined windows remain read-only; hidden/minimized windows missing from the CG inventory cannot be controlled; unknown minimized state defaults to false. Multi-display conversion is implemented but physical multi-display certification, permission-revocation stress and minimum-OS runtime checks remain outstanding. Native windows stay authoritative; no capture or overlay is created here.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
