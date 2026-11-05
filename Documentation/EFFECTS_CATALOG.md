# Effects Catalog and Implementation Requirements

Every effect descriptor must declare: identifier, display name, category, trigger support, parameter schema, capture requirement, 3D requirement, quality class, fallback, cleanup and tests.

## Current implementation boundary — 1.0.8/build 9
**1.0.8/build 9 locally validated.** The 5 November request selects **actual external Kinetiq.app**, not an approximation. **Effects → Kinetiq** explicitly launches/connects with consent; its physics/shaders/private mapping/input replay/parking execute externally, disabled by default in AETHER. Separate universal helper/build/upstream tests and **7/7** lifecycle/actual runtime admission tests pass locally. Independent fallback effects pass **6 functions / 7 cases**, zero skips. All four active-engine helper guards, selected-engine normal exit and exact local app launch/refresh are verified. Manual visual/policy/restoration and full M2/M3/M4/Living Window acceptance remain pending. Runtime admission is not a cross-process IPC lock: finish/cancel AETHER work before external launch, including independent starts during in-flight work not atomically prevented. See `KINETIQ_ENGINE.md` and `VISUAL_EFFECTS_VALIDATION.md` for exact receipts/limits.

Choose effects in Kinetiq's **wave menu → Setup…**. Explicitly select a **Close** effect such as **Fire**; nil selection is Off. Verify Kinetiq Enabled and Drag from Title Bar; saved settings can differ from defaults. No RPC lets AETHER select Kinetiq effects or synchronize exclusions/Reduce Motion. Its own prefetch/recapture may occur on raise; AETHER's one-shot budgets do not apply. This is the real external engine, not source/shader/texture copying into the catalog below.

### Separate public-API manual diagnostic fallback

The earlier bounded manual M3/M4 slice remains in `WindowEffectCoordinator`, separately from the external engine and planned registry catalog. It must not be presented as the requested Kinetiq integration and must not run while Kinetiq is active/pending. Its specific behavior is:

- Catalog **`wobbly`** corresponds only to a manual `.wobble` preview slice: one captured/uploaded texture, independent 17 × 13 fixed-120Hz spring lattice, UI 2s duration, original visible and interactive. No global native-drag hook or input-velocity sampling.
- Catalog **`dissolve`** has only a manual `.dissolveClose` slice: confirmation, one capture/upload, hidden preparation, real exact-generation/PID public AX close, full CG disappearance including off-screen rows (2s verification), **then** an original 1.1s procedural dissolve. Unconfirmed/refused closure never authorizes animation; Stop cannot undo close. No universal red-button/Cmd-W interception, hiding or rollback.
- Both use the existing one-shot privacy/lifetime rules, not `SCStream`; animation is at most 3s with 60fps target pacing (not measured throughput), one in-flight GPU command and 750ms wait while actual callback ownership persists. System OR config Reduce Motion selects a fade.

`BuiltinEffects.catalog` still contains `DeclarativeEffect` descriptors whose prepare/update/finish implementations are no-ops; **none becomes functional by registry membership**, including `wobbly`/`dissolve`. General parameters, triggers, quality tiers and full catalog behavior remain planned. Kinetiq's available effects do not implement these descriptors. Manual fallback testing is restricted to **AETHER Effect Disposable**, with Kinetiq stopped; see `VISUAL_EFFECTS_VALIDATION.md` and `API_CONTRACTS.md`.

## Planned catalog
| ID | Effect | Technical approach | Fallback |
|---|---|---|---|
| wobbly | Elastic window (manual preview slice only; full catalog planned) | Mesh deformation + spring constraints | Native move (planned catalog); manual Reduce Motion fade |
| genie | Genie-like transition | Mesh warp toward target rect | Fade/scale |
| morph | Morph | Interpolated geometry and transforms | Crossfade |
| fold | Fold | Subdivided mesh + 3D transform | Scale |
| flip | Flip | Perspective transform | Crossfade |
| magnet | Magnetic snap | Window geometry solver | Standard snap |
| float | Floating | Low-amplitude transform | None |
| shatter | Glass shatter | Triangulated fragments + particles | Dissolve |
| explode | Explode | Particle velocity field | Fade |
| dissolve | Dissolve (explicit confirmed-close slice only; full catalog planned) | Noise threshold + alpha after verified native close in manual slice | Fade |
| burn | Burn | Noise edge + emissive rim | Dissolve |
| portal | Portal | Radial warp + mask + depth | Scale/fade |
| depth-of-field | DOF | Blur pyramid + depth mask | Simple blur |
| ripple | Ripple | Displacement shader | Fade |
| liquid-morph | Liquid morph | Flow/displacement field | Morph |
| workspace-cube | Cube | AETHER logical workspace scene | Slide |
| orbit | Orbit | Spatial layout scene | Grid overview |
| gravity | Gravity | Physics scene | Scale/fade |
| expose-3d | Exposé 3D | Perspective scene layout | Grid overview |

A catalog entry is not a shipped effect. Each effect must have implementation, preview, parameter validation, quality behavior, cancellation and tests.
