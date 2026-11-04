# AETHER 1.0 — Product Specification

## Product
AETHER — The Desktop, in Motion.

A native macOS application combining practical window organization with a premium, configurable visual-effects system.

## Approved decisions
- Product name: AETHER.
- Independent from Kinetiq.
- Hybrid rendering: native window control + temporary Metal overlay.
- Effects philosophy: full catalog, including experimental and dramatic presets.
- Compatibility: public APIs as stable baseline; advanced techniques isolated and optional.
- Strategy: complete product delivered through milestone gates.

## Product pillars
1. Motion: transitions and window animation.
2. Physics: spring dynamics, inertia, elastic deformation and magnetic attraction.
3. Spatial: depth, perspective, 3D workspace visualization.
4. Intelligence: adaptive layouts, rules and optional local LLM commands.
5. Control: effects library, animation studio, diagnostics and preferences.

## Core product requirements
- Discover and identify windows where public APIs permit.
- Inspect window metadata and capabilities.
- Move/resize/focus supported windows through Accessibility APIs.
- Capture selected windows with ScreenCaptureKit after explicit permission.
- Render temporary visual representations with Metal.
- Reconcile native state after every transition.
- Provide native fallback for unsupported or denied operations.
- Support configurable effects and composed sequences.
- Provide tiling, snapping, logical workspaces and groups.
- Provide a dashboard for runtime state, permissions, performance and diagnostics.

## Important platform limitation
A third-party macOS application cannot replace WindowServer or universally intercept all native application window lifecycle animations. AETHER must not promise universal close/minimize animation replacement. Effects are triggered by AETHER-controlled actions, observed supported events, or explicit workflows. Native macOS behavior remains in control otherwise.

## Release 1.0 effect catalog
Wobbly, Genie-style transition, Morph, Fold, Flip, Magnet, Float, Shatter, Explode, Dissolve, Burn, Portal, Depth of Field, Ripple, Liquid Morph, Workspace Cube visualization, Orbit, Gravity and Exposé 3D.

An effect is only considered shipped when it is registered, configurable, integrated, tested, and has a fallback.
