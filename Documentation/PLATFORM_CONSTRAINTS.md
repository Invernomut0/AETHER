# macOS Platform Constraints

## Window lifecycle
There is no general public API allowing a third-party app to intercept and replace every other app's native open/close/minimize animation. AETHER can animate actions it initiates and supported observed workflows. Native lifecycle remains authoritative.

## Accessibility
AXUIElement access is permission-gated and application-dependent. Position, size, title and settable attributes may be missing or read-only. Always inspect capabilities and verify changes.

## CoreGraphics
Window lists and IDs are useful for discovery and correlation, but do not constitute a universal window-control API. IDs may be reused and must not be persisted as durable identity.

## ScreenCaptureKit
Capture requires explicit user permission and may not expose protected content. Streams can fail, stop, or deliver stale frames. Handle lifecycle and backpressure.

## Overlay
Overlay NSWindows can interact with Spaces, full-screen apps, Mission Control, Stage Manager, input routing and z-order in complex ways. Test each supported behavior. Do not claim full control of system compositor.

## Private APIs
Private APIs remain prohibited in AETHER's stable path. The user's 5 November 2026 contract explicitly permits private `_AXUIElementGetWindow` mapping, global event taps/click replay and temporary off-screen native-window parking in the **optional external Kinetiq engine**. This path is disabled by default in AETHER, requires explicit risk consent and trusted bundle selection, and cannot be required for stable release success. Keep runtime/availability safeguards and the separate public-API diagnostic fallback; see `KINETIQ_ENGINE.md`.

Private AX/window behavior can break on macOS updates. Event taps and replay do not provide universal native close/minimize interception; app-specific controls, save sheets, Spaces and full-screen behavior need actual checks. Off-screen membership is not proof of closure. Parking can fail or remain unrecovered after a crash; neither normal quit nor process disappearance certifies window restoration.

Kinetiq is a separate permission identity and may show its own Accessibility/Screen Recording prompts after explicit launch. AETHER cannot transfer grants, suppress OS indicators or certify event-tap readiness by observing a PID. Its own budgets, exclusions and Reduce Motion do not automatically govern Kinetiq. AETHER window mutations/capture/effects must be interlocked while the external engine or its launch outcome is active/pending; discovery remains passive.

## Distribution
Review App Sandbox, hardened runtime, Accessibility, Screen Recording and notarization requirements for the selected distribution channel. Do not assume App Store approval for broad window-control behavior.
