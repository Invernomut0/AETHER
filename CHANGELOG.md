# Changelog

## 1.0.1 — M0 bootstrap (2026-11-04)
- Validate on macOS with Xcode 27.2 / Swift 6.4.2 and the official Metal Toolchain.
- Fix display syntax, missing cross-module model initializers, permission isolation and SwiftUI app entry-point builds.
- Add persistent configuration bootstrap, schema 0 migration, unsupported-schema protection and cancellation-aware lifecycle.
- Connect startup and passive permission diagnostics to the dashboard; prompts remain explicit user actions.
- Add unified logging, filesystem-backed configuration/lifecycle tests, coverage-enabled CI and shared app schemes.
- Add repeatable local application builds; native control and Living Window remain gated by M1 and M2.
- Keep Wobbly as an architectural reference only; no GPL source was copied.

## 1.0.0-foundation
- Initial AETHER repository scaffold.
- Modular Swift Package structure.
- Shared models and protocol contracts.
- Initial SwiftUI dashboard.
- Metal shader starter library.
- Documentation, Copilot instructions and test plan.
