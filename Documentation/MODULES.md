# Module Specifications

Current status: **1.0.8/build 9 locally validated**. Real external Kinetiq's optional private AX/input replay/parking path is separate from public diagnostics. Build/tests/actual runtime admission/compatible coverage/both built versions, all four active-engine exit-2 guards, identity-checked normal engine exit, exact local app relaunches and Quick Look/Finder refresh are verified. Full M2 physical/platform, M3/M4 and Living Window gates stay **NOT accepted**. Publication receipts are tracked in `TODO.md`, separately from remote CI Review. See `KINETIQ_ENGINE.md` and `VISUAL_EFFECTS_VALIDATION.md`.

## AETHERShared
Pure value types, identifiers, errors, configuration and event contracts. No UI, capture or GPU ownership. `WindowCapabilities.canClose` defaults false, including when decoding older records missing the field; malformed types still fail.

## AETHERCore
`KinetiqEngineCoordinator` owns MainActor process metadata, explicit consented launch/connect, retained pending/late launch callbacks and verified normal termination of a separate Kinetiq.app. Start/Stop waits are bounded to 10 seconds; OS requests cannot be revoked, uncertain ownership blocks replacement, no forced termination is used. Status observes independent instances without taking control. `isActive` includes pending/running independent engines for command interlocks. There is no linked Kinetiq code or readiness/settings IPC; process existence is not effect readiness. AETHER grants/capture budgets/exclusions/Reduce Motion do not govern Kinetiq. See `KINETIQ_ENGINE.md`.

Application lifecycle, event routing, orchestration, permission state/recovery. Preview defaults to `.snapshot`: one GPU-completed static image up to 5s, not an animation. `.live` is explicit continuous diagnostics. Both check exact CG ID/PID/visibility every 100ms before AX; next AX starts at 500ms, avoiding duplicate caller validation. Current capture regression passes **22 functions / 26 cases**, two denial skips; historical 1.0.7 remains in `M2_VALIDATION.md`.

`WindowEffectCoordinator` separately owns manual `.wobble` / `.dissolveClose` transactions: one snapshot/upload, native identity and privacy validation, bounded monotonic animation, cancellation and cleanup. Wobble preserves the visible/interactive original; Close prepares hidden and animates only after a real verified native close. Unconfirmed close forbids automatic retry; Stop cannot undo closure. UI durations are 2s / 1.1s, animation maximum 3s, approximately 60fps target pacing, system OR config Reduce Motion fade. General motion-engine completion is not implied. See `API_CONTRACTS.md`.

## AETHERWindowManager
Window discovery via CoreGraphics; actor-owned Accessibility capability probing/control; topology and coordinates. This stable AETHER adapter correlates AX to CG using a verified public strategy, never a private ID API or first-window fallback. That rule does not prohibit the separately authorized experimental Kinetiq process's private mapping/parking. Probe `canClose` from same-PID enabled close button and AXPress availability. Exact registered generation/process/AX/CG validation precedes one native close request; success requires full CG inventory disappearance including off-screen rows within a 2s verification deadline. `NativeWindowCloseError.outcomeUnconfirmed` preserves post-request uncertainty; closure receipts authorize `isWindowClosed` rechecks, not retries/rollback.

## AETHERCapture
Own on-demand screenshots/diagnostic streams under one mutually exclusive lease **per capture owner**. Preview/effect owners are separate; UI serializes commands. One `SCScreenshotManager.captureImage`, no SCStream/refresh loop, BGRA at most 1600px. Wait 5s/independent cleanup 3s bound Swift waits, not callbacks; retain ownership until completion, release successful snapshot lease before rendering. Live explicitly streams at 30fps; consent/exclusions apply, no indicator guarantee. Current five-profile merged **line** coverage: snapshot **95.20%**, stream **94.95%**, coordinator **92.86%**. Equal historical percentages do not reuse historical profiles. See `Sources/AETHERCapture/README.md` and visual validation.

## AETHERRendering
Own Metal pipelines/overlay GPU lifetime; general render graph/pooling/adaptation remain planned. Hidden `prepareEffect` uploads once, rendering reuses texture/mesh/dissolve. One in-flight command, 750ms wait, callback ownership beyond removal/timeout; panels cannot become key/main and ignore input. Zero relative target only post-close. Current component/effects tests pass; presenter **90.75% line coverage**, not shader/scanout/fps certification; texture bytes estimated.

## AETHEREffects
Effect descriptors, registry, parameter validation and planned composition. `DeclarativeEffect` prepare/update/finish remain no-op; built-ins are not functional merely because descriptors exist. Explicit coordinator wobble/close lives outside that generic lifecycle and is only a bounded manual diagnostic slice, not a fully shipped catalog or Kinetiq substitute. Kinetiq's actual model/shaders execute externally and are configured in its own Setup, not registered/copied here. See `EFFECTS_CATALOG.md`.

## AETHERPhysics
Pure Sendable spring/world foundation, independent wobble lattice (17 × 13 default, 2...65 per axis). Fixed 1/120s steps/fractional accumulator, max 0.1s/12 steps, discarded excess time; bounded velocity/displacement, rest/neighbor springs, damping/double buffering/rest settling. Invalid input rejected without mutation. Local tests pass, WobbleSimulation **100% line coverage**; not branch/performance/full physics acceptance. General particles/constraints/native drag/profiling remain planned.

## AETHERAnimation
Scheduler/easing foundation; general timeline/keyframes/tracks and bindings remain incomplete. The Core manual coordinator supplies a bounded monotonic effect loop with cancellation, not a replacement for full M3. M4 fixed-step physics is independent from its wall-clock presentation pacing.

## AETHERLayouts
Tree-based tiling, layout validation, constraints, snapping and logical workspace model.

## AETHERPersistence
Versioned config, preset import/export, transactional writes and migrations. SQLite is the planned release store; current JSON repositories are bootstrap implementations.

## AETHERIntelligence
Rule evaluation and optional LLM command interpretation. No captured pixels or sensitive window titles sent to external providers.

## AETHERInterface
**Effects** hosts `KinetiqEnginePanel`: trusted app selection, explicit risk checkbox, Start / Connect, Stop Kinetiq, Cancel wait, passive Refresh and instructions for the real wave menu/Setup. Choosing a bundle or startup never launches it. The panel warns that Kinetiq needs separate permissions, uses private mapping/event taps/click replay/parking and survives AETHER exit; status is not readiness. No fake integrated effect settings are exposed.

Windows retains native diagnostics, Snapshot 5s/Live, Wobble and destructive Close confirmation. Actual RuntimeModel admission rejects all six commands while Kinetiq active/pending, allows refresh, rechecks after config await; panels observe every **500ms while visible**. Actual-model lifecycle test passes **7/7**, Interface linked **only in CoreTests**, no production Core cycle. **Not a cross-process lock**: independent start during in-flight work is not atomically prevented; finish/cancel first. Structured cancellation/Stop/Escape affects AETHER visuals, **not Kinetiq**, and cannot undo close. Manual fallback uses Effect Disposable; other destinations remain scaffolds. See visual validation for exact receipts/manual gates and expanded Interface/Effects coverage perimeter.
