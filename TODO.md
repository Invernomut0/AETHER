# Engineering Tasks

Owner: AETHER engineering (GitHub Copilot assisted). No delivery dates are committed.

## Review
- M0: verify the startup dashboard and explicit permission buttons on the local Mac.
- M0/M1: inspect the committed GitHub CI workflow; local results are not a CI run.
- M1: review the Windows UI with VoiceOver, explicit denial/regrant and the rebuilt app's own Accessibility identity.
- M1/M9: certify multiple physical displays/scales, app-specific AX constraints, permission revocation during IPC and macOS 14 runtime.
- M2 exit gate: rerun with explicit Screen Recording consent on the test host (`AX=true`, `Recording=true`) and validate real ScreenCaptureKit output end-to-end.
- M2: complete manual checks for Spaces/full-screen z-order behavior, multi-display overlay behavior and crash/recovery cleanup.
- M2: review denylist coverage for unknown credential managers and maintain `configuration.captureExcludedBundleIDs` guidance.

## To Do
- M2 / Gate 0: collect explicit-consent live evidence (fresh frame presented and reliably removed) before marking M2 accepted.
- M2: validate denial/revocation in flight, protected-content behavior, stress/runtime limits, and manual no-orphan/no-interaction visual checks.
- M1/M2: unlock the desktop and finish secure input before rerunning interactive gates; direct AX probes returned application proxies while locked, correctly rejected as window identities.
- M3–M9: wait for the M2 capture/overlay exit gate, then proceed in order. M3 animation is needed to complete the broader Living Window Gate 0 before scaling the effects catalog.

## Done
- Pass final default validation and both app builds at 1.0.4/build 5; execute 33 functions / 38 cases, explicitly skip 17 unavailable/opt-in functions. Verify both live scripts refuse the locked/unauthorized host with exit 2.
- Version the first M2 implementation slice as 1.0.4 (build 5); implementation is complete for this increment but the M2 capture/overlay exit gate remains pending.
- M2 implementation: add ScreenCaptureKit callback path, bounded frame flow, preview transaction orchestration, privacy/permission checks and Metal overlay teardown hardening.
- M1: replace first-window selection with unambiguous correlation, AX actor ownership, capabilities, generations and selected-window readback.
- M1: integrate the Windows panel and real resizable/fixed/overlapping Test Lab windows; pass all 14 native tests with explicit opt-in.
- M1: reproduce and fix AX/CG publication lag and display-edge resize clamping without weakening geometry assertions.
- M0: validate the initial build before source edits and install the official missing Metal Toolchain.
- M0: correct cross-module initializers, Swift 6 permission isolation, display syntax and SwiftUI entry-point compilation.
- M0: add configuration bootstrap/migration, cancellation-aware lifecycle, logging and live permission diagnostics.
- M0: add filesystem-backed tests, coverage-enabled validation, app builds and shared schemes.
- Initialize the local Git repository; version the bootstrap as 1.0.1 (build 2) and its publication as 1.0.2 (build 3).
- Configure the owner-provided `origin`: `https://github.com/Invernomut0/AETHER.git`.