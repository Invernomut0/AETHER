# Security and Privacy

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
