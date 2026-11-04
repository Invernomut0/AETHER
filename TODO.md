# Engineering Tasks

Owner: AETHER engineering (GitHub Copilot assisted). No delivery dates are committed.

## Review
- M0: verify the startup dashboard and explicit permission buttons on the local Mac.
- M0/M1: inspect the committed GitHub CI workflow; local results are not a CI run.
- M1: review the Windows UI with VoiceOver, explicit denial/regrant and the rebuilt app's own Accessibility identity.
- M1/M9: certify multiple physical displays/scales, app-specific AX constraints, permission revocation during IPC and macOS 14 runtime.

## To Do
- M2 / Gate 0: implement capture output, bounded frames, Metal overlay transaction, cancellation and guaranteed cleanup with user-granted Screen Recording.
- M3–M9: proceed in order through `Documentation/MILESTONE_TASKS.md`; effect descriptors are not implemented effects.

## Done
- Version the validated M1 slice as 1.0.3 (build 4); full local validation passes all 33 test functions / 38 cases.
- M1: replace first-window selection with unambiguous correlation, AX actor ownership, capabilities, generations and selected-window readback.
- M1: integrate the Windows panel and real resizable/fixed/overlapping Test Lab windows; pass all 14 native tests with explicit opt-in.
- M1: reproduce and fix AX/CG publication lag and display-edge resize clamping without weakening geometry assertions.
- M0: validate the initial build before source edits and install the official missing Metal Toolchain.
- M0: correct cross-module initializers, Swift 6 permission isolation, display syntax and SwiftUI entry-point compilation.
- M0: add configuration bootstrap/migration, cancellation-aware lifecycle, logging and live permission diagnostics.
- M0: add filesystem-backed tests, coverage-enabled validation, app builds and shared schemes.
- Initialize the local Git repository; version the bootstrap as 1.0.1 (build 2) and its publication as 1.0.2 (build 3).
- Configure the owner-provided `origin`: `https://github.com/Invernomut0/AETHER.git`.