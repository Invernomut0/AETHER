# AETHERPhysics

Fixed-step simulation, springs, mesh constraints and particles.

## Independent wobble lattice — locally tested diagnostic slice

For the explicitly requested **1.0.8/build 9** manual-effect slice, `WobbleSimulation` owns pure Sendable displacement/velocity values, not native windows, clocks or Metal resources. Default resolution is **17 columns × 13 rows (221 nodes)**; each axis accepts 2...65 nodes, with finite positive source size up to 16384 points per edge.

- Fixed **1/120s** semi-implicit Euler steps via `SpringSolver`; fractional time carries forward.
- At most **0.1s / 12 steps per advance**; discard excess elapsed time instead of accumulating catch-up work.
- Free edges, neighboring springs (80), springs to rest (100), damping (14), unit mass and double-buffered previous-step propagation without traversal bias.
- Smooth normalized impulse falloff; displacements limited to 25% of the shorter edge and velocities to 8 times that edge per second. Lattice-wide quiet-state settling snaps to exact rest.
- Reject invalid duration, impulse or anchor without state mutation.

The Core coordinator applies a fixed demo impulse, renders one uploaded snapshot and leaves the original visible/interactive. General native-drag velocity sampling/integration, full constraints/particles and broad profiling are **not implemented by this slice**. Presentation's 60fps target is separate from 120Hz simulation, not an achieved performance claim.

Passed `WobbleSimulationTests` cover rest/grid, first/second-step identities, symmetry/coupling, chunk/fractional-step determinism, bounded catch-up, saturation/exact-rest recovery and invalid inputs. Verified final default-test receipt and fresh five-profile merged report measure **WobbleSimulation 100% source-line coverage** (`/tmp/aether-kinetiq-final-coverage.log`). This is not branch/performance, general physics, full M2/M3/M4 or Living Window acceptance. Expanded Interface/Effects linkage changes total coverage's perimeter; historical 1.0.7 is not a like-for-like comparison. See `Documentation/TESTING.md` and `Documentation/VISUAL_EFFECTS_VALIDATION.md`.

See `Documentation/MODULES.md` and the relevant acceptance criteria before implementation.
