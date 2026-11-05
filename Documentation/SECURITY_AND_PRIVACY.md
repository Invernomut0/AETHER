# Security and Privacy

## AETHER-owned operations

The controls below apply to AETHER's native diagnostics and capture/effect coordinators, not automatically to external software.

- Capture only the selected window and only while an effect requires it.
- Make Screen Recording purpose and status visible to the user.
- Never persist captured window pixels by default.
- Never send captured window content to an LLM or network service.
- LLM integration receives user-authored commands and explicitly selected metadata only.
- Exclude password managers, secure input and user-configured applications from capture.
- Provide a global pause/disable switch.
- Store preferences and presets locally.
- Do not execute code from imported effect packages.
- Imported presets are declarative data validated against a strict schema.
- Redact sensitive window titles from diagnostic exports unless user opts in.

## Opted-in external Kinetiq engine

The 5 November contract authorizes private AX window mapping, event-tap/click replay and temporary off-screen parking only as an explicitly labelled experiment. **Save work and test disposable windows first.** Parking changes actual native positions; failed cleanup or a crash can leave windows displaced. Restoration must be observed, not inferred from process exit. Never bypass OS permissions or recording indicators.

- Start/connect requires the risk checkbox and a trusted local Kinetiq.app. Validation checks canonical bundle/executable identity, metadata and effects resources; it is **not signature verification or authentication**. Do not launch an untrusted app merely because metadata matches.
- Kinetiq requests **its own** Accessibility and Screen Recording access. AETHER's permission cards/grants do not authorize Kinetiq. Explicit launch may display Kinetiq's prompts; grant manually in System Settings and restart only if required. No TCC editing, auto-allow, autostart or indicator suppression.
- Kinetiq's own settings govern capture, exclusions, physics and effects. AETHER's `captureExcludedBundleIDs`, `effectsEnabled`, Reduce Motion and snapshot/callback budgets are not an external-engine policy channel. Configure Kinetiq deliberately before interaction; no RPC transfers those settings. Disable/quit Kinetiq separately when needed.
- Kinetiq can prefetch/recapture on window raise, not only once per drag/close. Observe indicators before/during/after use; persistence/recent use is not automatically a leak, nor is absence guaranteed.
- AETHER focus/move/capture/effects must be blocked for running, independently launched or unresolved-launch Kinetiq instances; discovery/status refresh is allowed. Final runtime interlock evidence belongs to the main workflow.
- Cancellation ends the launch/quit **wait**, not an already-issued OS request. Retain pending ownership and late handles. Normal Stop uses verified `NSRunningApplication.terminate()` only; no forced kill. Refusal/timeouts remain actionable failures, not cleanup proof.
- Kinetiq continues after AETHER quits or the Effects page closes. Use **Stop Kinetiq** or wave menu → **Quit Kinetiq**. Normal Kinetiq termination invokes its cancellation/AX-restoration path, but no universal restoration or crash-recovery guarantee is made.

See `KINETIQ_ENGINE.md` for separate-process licensing/attribution, trust boundaries and manual validation. The external bridge does not attest that all upstream privacy or recovery behavior has been audited.
