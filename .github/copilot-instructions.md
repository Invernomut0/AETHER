# AETHER Copilot Engineering Instructions

You are implementing AETHER, a native macOS window manager and effects engine.

## Non-negotiable architecture
1. Native application windows are the source of truth.
2. Metal overlays are temporary visual representations only.
3. Never claim that third-party apps expose a universal close/minimize interception API.
4. Use public Apple APIs in stable paths. Isolate experimental/private techniques behind disabled adapters and compile-time/runtime guards; do not make them required.
5. Accessibility and Screen Recording permissions are explicit user-granted capabilities. Never bypass, fake, or silently assume them.
6. Every asynchronous operation must support cancellation, timeout where appropriate, error reporting and cleanup.
7. No placeholder, mock, `fatalError`, empty implementation or TODO may be described as complete.
8. Keep module boundaries and avoid circular dependencies.
9. Swift 6 strict concurrency: make actor isolation and Sendable ownership explicit.
10. Metal resources must have explicit lifetime and synchronization rules.

## Required workflow for every task
- Read `Documentation/ARCHITECTURE.md`, `Documentation/ROADMAP.md`, and the relevant module spec first.
- Identify the milestone and acceptance criteria.
- Inspect current code before editing.
- Implement the smallest complete vertical slice.
- Add unit/integration tests.
- Run `swift build` and `swift test` on macOS.
- Update documentation and `CHANGELOG.md`.
- Report files changed, tests run, results, limitations and follow-up tasks.

## API discipline
- Verify API names, availability and signatures against the installed Apple SDK and official documentation.
- Do not invent ScreenCaptureKit, Accessibility, CoreGraphics, AppKit or Metal APIs.
- If an API is unavailable or behavior is undocumented, implement a capability check and fallback.
- Never assume `CGWindowID` is a durable identity.
- Never assume every AX element exposes position, size, title or settable attributes.
- Do not treat `SCWindow` as an interactive native window.
- Do not transfer `NSWindow`, `AXUIElement`, `MTLTexture`, `CMSampleBuffer` or other non-Sendable objects across actors without an explicit safe ownership design.

## Definition of Done
A feature is done only when:
- It builds on the declared minimum macOS version.
- Tests pass.
- It is integrated into the app.
- Failure paths are implemented.
- Permissions and fallback behavior are documented.
- Diagnostics are available.
- No resource leak or orphan overlay is observed in its test plan.
