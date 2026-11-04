# Effects Catalog and Implementation Requirements

Every effect descriptor must declare: identifier, display name, category, trigger support, parameter schema, capture requirement, 3D requirement, quality class, fallback, cleanup and tests.

| ID | Effect | Technical approach | Fallback |
|---|---|---|---|
| wobbly | Elastic window | Mesh deformation + spring constraints | Native move |
| genie | Genie-like transition | Mesh warp toward target rect | Fade/scale |
| morph | Morph | Interpolated geometry and transforms | Crossfade |
| fold | Fold | Subdivided mesh + 3D transform | Scale |
| flip | Flip | Perspective transform | Crossfade |
| magnet | Magnetic snap | Window geometry solver | Standard snap |
| float | Floating | Low-amplitude transform | None |
| shatter | Glass shatter | Triangulated fragments + particles | Dissolve |
| explode | Explode | Particle velocity field | Fade |
| dissolve | Dissolve | Noise threshold + alpha | Fade |
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
