# ADR 0003: Native Window Is Authoritative

Status: Accepted

The actual application window remains authoritative. Overlay frames are transient visual surrogates only.

Consequences:
- Never persist overlay geometry as native truth.
- Always reconcile after effect completion or failure.
- Overlay must not become a permanent noninteractive clone.
