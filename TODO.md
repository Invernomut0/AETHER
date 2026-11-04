# Engineering Tasks

Owner: AETHER engineering (GitHub Copilot assisted). No delivery dates are committed.

## Review
- M0: verify the startup dashboard and explicit permission buttons on the local Mac.
- M0/M1: inspect the committed GitHub CI workflow; local results are not a CI run.
- M1: review the Windows UI with VoiceOver, explicit denial/regrant and the rebuilt app's own Accessibility identity.
- M1/M9: certify multiple physical displays/scales, app-specific AX constraints, permission revocation during IPC and macOS 14 runtime.
- M2: review consented capture/overlay evidence and the initial macOS UserNotificationCenter focus interruption in `Documentation/M2_VALIDATION.md`.
- M2: complete manual checks for Spaces/full-screen z-order behavior, multi-display overlay behavior and crash/recovery cleanup.
- M2: review denylist coverage for unknown credential managers and maintain `configuration.captureExcludedBundleIDs` guidance.

## To Do
- M2: validate denial/revocation in flight, protected-content behavior, stress/runtime limits, and manual no-orphan/no-interaction visual checks.
- M1/M2: retain unlocked-desktop and secure-input prerequisites for future interactive runs; both permissions are now granted to the test host.
- M3–M9: proceed in order after reviewing remaining M2 acceptance checks. The local capture/overlay proof has passed; M3 animation will still be needed to complete the broader Living Window Gate 0 before scaling the effects catalog.

## Done
- Validate 1.0.6/build 7: real target move/minimize/close and same-coordinator recovery pass four post-fix suites (13 functions / 15 cases, two denial skips each); M1 regression 14/14, default 34 functions / 39 cases with 17 skips, both app builds. Reproduce/fix already-stopped SCK closure cleanup without weakening ownership; final live line coverage lease 93.56%, preview 93.39%. Retain failed baseline and rejected stale coverage report in M2 validation.
- Validate 1.0.5/build 6: Swift/both app builds, default 34 functions / 39 cases with 16 skips, and separate consented coverage rerun (12 executed, two denial skips). Live line coverage: capture lease 88.70%, preview coordinator 88.43%. Record the missing-fixture attempt rather than counting it as a pass.
- M2 local capture/overlay proof: after explicit user consent, pass three consecutive capture suites (12 functions executed, two denial tests inapplicable) and native regression 14/14. Preserve the initial focus failure; full M2 platform acceptance remains pending.
- Pass final default validation and both app builds at 1.0.4/build 5; execute 33 functions / 38 cases, explicitly skip 17 unavailable/opt-in functions. Verify both live scripts refuse the locked/unauthorized host with exit 2.
- Version the first M2 implementation slice as 1.0.4 (build 5); its live proof was initially blocked and subsequently passed after user consent, documented in 1.0.5 (build 6).
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