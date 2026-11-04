# Performance Budget

Targets must be measured on a documented Apple Silicon reference machine.

- Baseline 60 FPS for supported simple effects.
- Up to 120 FPS when display refresh and GPU workload allow.
- No continuous render loop while idle.
- Base app memory target <250 MB before capture/effect workload.
- Capture queues bounded (initial target depth 3).
- Drop stale frames rather than queueing latency.
- Dynamic quality tiers: Auto, Low, Balanced, High, Ultra.
- Under pressure: lower capture resolution, reduce blur passes, reduce mesh density, reduce particle count, pause nonessential effects.

Report p50/p95/p99 frame times, not only average FPS. Separate capture latency from render latency. Do not claim GPU utilization if the chosen API does not expose a reliable measurement.
