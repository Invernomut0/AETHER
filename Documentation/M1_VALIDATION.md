# M1 local validation — 2026-11-04

Version: 1.0.3 (build 4). Environment: the same Apple Silicon Mac, Xcode 27.2 / Swift 6.4.2 and official Metal Toolchain used for M0. Deployment target remains macOS 14; this is not minimum-OS runtime certification.

## Acceptance boundary

The M1 gate is native Test Lab windows discovered and controllable where supported. The implementation uses public CoreGraphics/Accessibility/AppKit APIs only and contains no Wobbly source. M2 capture/overlay and the Living Window gate are not implemented by this slice.

`NativeWindowService` shares one actor-owned AX registry between discovery and control. Mutually unique PID/frame/optional-title correlation and current process launch identity produce session handles. Exact overlapping windows intentionally have no handle. Every command validates current identity and capability; CGWindowID alone is never authorization to control.

## Real integration evidence

`AETHER_RUN_WINDOW_INTEGRATION=1 swift test --filter NativeWindowTests` passed all **14 tests**, with no integration skips, against a separately running Test Lab launched with `--m1-fixtures`. Only Test Lab fixtures were mutated:

- Actual desktop enumeration, pre-cancellation and AppKit/CG geometry conversion.
- Required fixture/process presence and distinct handles for multiple windows in one process.
- Moving/resizing one selected window, confirming a second window is unchanged and restoring the original frame.
- Raising/focusing that exact selected window with AX readback.
- Two identical title/frame windows remaining read-only.
- Fixed-size capability probing and typed resize rejection.
- Forged generation rejection, invalid geometry, cancelled controls and disappearance after closing a disposable fixture.
- Correlation checked against AX metadata collected from the real fixture process.

No Screen Recording request or capture is performed. A passive check reported **Accessibility true / Screen Recording false** for the test host. CG titles were redacted; AX geometry/title located the overlap group without assigning a unique identity. Accessibility was already granted; it was not bypassed or changed by the tests. This does not prove that the separately signed AETHER application is authorized.

## Bugs found by the real tests

1. AX may acknowledge geometry before WindowServer publishes the same CG bounds. Success now requires agreement across successive observations, not setter return codes.
2. Resizing at the current display edge can clamp height (observed request 452 pt vs actual 449 pt). Move precedes growth; size settles, then final position is reapplied. Exact frame assertions remain in place.
3. CG titles can be absent without capture permission. Tests now identify ambiguous groups through real AX geometry instead of relying on protected CG titles.
4. Freshly launched AppKit windows can initially expose transient AX proxies without geometry. The service requires `AXWindow` role; tests wait up to ten seconds for observed fixture readiness and fail if it never arrives.

## Reproduction

Quit Test Lab, grant Accessibility explicitly to the test host if desired, then run `bash Scripts/test-window-integration.sh`. It builds both bundles and opens fresh fixtures. Failure to provide consent/fixtures fails opted-in tests. Repeat runs require new fixtures because the disposable window is deliberately closed.

`bash Scripts/validate.sh` covers package build, coverage-enabled default tests, aggregate coverage and both app builds. The default native suite executes three non-mutating tests and explicitly skips eleven fixture tests; that default run alone does not pass M1's live gate.

Final full run: `AETHER_RUN_WINDOW_INTEGRATION=1 bash Scripts/validate.sh` exited 0 after recreating Test Lab fixtures. All 33 test functions (38 parameter-expanded cases) passed, including all 14 native tests without skips. Both 1.0.3/build 4 bundles compiled. Aggregate linked-library line coverage was 72.15%; `WindowAccessibilitySession` 88.12%, `NativeWindowService` 90.00%, `WindowCorrelation` and `WindowGeometry` 100%. This is coverage of linked library code, not certification of the UI or unimplemented capture/rendering pipeline. Existing nonblocking CoreSimulator-version and generated Metal-bundle warnings remain.

## Remaining review and limitations

- Inspect the rebuilt AETHER Windows panel and explicit permission buttons; app trust is separate from CLI trust and ad-hoc builds can require regranting.
- Manually deny/regrant and revoke access during IPC; no automated test changes user consent.
- Certify physical multi-display/scaling, Spaces/fullscreen, VoiceOver and minimum macOS runtime. Coordinate conversion exists, but these environments were not certified here.
- Refresh is explicit; there is no AXObserver lifecycle stream. Commands always revalidate; missing/ambiguous targets fail closed.
- Unavailable apps degrade to read-only within the five-second AX discovery budget. Per-message timeout is 150 ms; system CG/AppKit calls are not forcibly preemptible.
- Geometry writes are not atomic. A failed/cancelled operation can leave partial native changes; the generation is invalidated and refresh is required. No blind rollback is attempted over possible user changes.
- Remote CI results, long-run soak, release signing and notarization are separate from this local gate.