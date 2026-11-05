# AETHER Copilot Engineering Instructions

You are implementing AETHER, a native macOS window manager and effects engine.

## Non-negotiable architecture
1. Native application windows are the source of truth.
2. Metal overlays are temporary visual representations only.
3. Never claim that third-party apps expose a universal close/minimize interception API.
4. Use public Apple APIs in stable paths. The user's 5 November 2026 contract explicitly authorizes private AX window mapping, global event taps/click replay and temporary off-screen native-window parking ONLY in an explicitly opted-in experimental path. Keep that path disabled by default, isolated behind appropriate runtime/availability guards (and compile-time guards for any in-process adapter), with a usable public-API diagnostic fallback; never make private techniques a stable release dependency.
5. Accessibility and Screen Recording permissions are explicit user-granted capabilities. Never bypass, fake, or silently assume them.
6. Every asynchronous operation must support cancellation, timeout where appropriate, error reporting and cleanup.
7. No placeholder, mock, `fatalError`, empty implementation or TODO may be described as complete.
8. Keep module boundaries and avoid circular dependencies.
9. Swift 6 strict concurrency: make actor isolation and Sendable ownership explicit.
10. Metal resources must have explicit lifetime and synchronization rules.

## Kinetiq external-engine boundary
- Read `Documentation/KINETIQ_ENGINE.md` before changing engine integration. Use the actual separately installed Kinetiq.app engine, not AETHER's independent manual wobble/dissolve as a substitute.
- Keep Kinetiq code, shaders and assets out of AETHER targets/bundles. Preserve upstream GPL-3.0-or-later, NOTICE, third-party notices and CC-BY-4.0 texture attribution in the original checkout; do not unilaterally relicense AETHER or assert a general GPL incompatibility/exemption.
- Launch/connect only after explicit experimental consent and trusted local bundle selection/validation. Metadata is not authentication. Never autostart, auto-grant permissions, edit TCC or suppress recording indicators. AETHER grants do not grant Kinetiq access.
- Block AETHER focus/move/capture/effect admission while Kinetiq is running, starting/stopping or its OS launch outcome is unresolved, including independently launched instances; passive discovery remains allowed. Verify this interlock in code, not just disabled buttons.
- Retain pending launch ownership and late callback handles after cancellation/timeout; an issued Launch Services request cannot be revoked. Start/Stop waits are bounded to 10 seconds. Quit only the verified selected instance via normal termination, never forced kill; retain uncertain ownership for retry.
- No IPC/readiness protocol exists. A process handle is not proof of event-tap, permission, shader or effect readiness. Settings belong to Kinetiq's wave menu/Setup; AETHER capture budgets, exclusions and Reduce Motion do not automatically apply.
- Native windows remain authoritative even when temporarily parked. Restoration is a target requiring observation, not a guarantee: normal Kinetiq quit requests its cleanup, but crashes/failed AX restoration may leave windows displaced. Warn users, save work and use disposable fixtures first. Kinetiq survives AETHER exit.

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
