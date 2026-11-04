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
Private APIs are prohibited in stable paths. If an experimental adapter is explored, isolate it, disable by default, document OS-version risk and provide a public-API fallback. Never make release success depend on it.

## Distribution
Review App Sandbox, hardened runtime, Accessibility, Screen Recording and notarization requirements for the selected distribution channel. Do not assume App Store approval for broad window-control behavior.
