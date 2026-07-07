---
name: add-actuator
description: Add health/info/metrics actuator endpoints to a pico-boot app, or contribute HealthIndicator/InfoContributor components. Use when adding Kubernetes probes, health checks, or observability endpoints.
argument-hint: [dependency to health-check, e.g. "database", "redis"]
allowed-tools: Read Grep Glob Write Edit
---

# Add Actuator

Add pico-actuator health/info endpoints for: $ARGUMENTS

## What pico-actuator provides

- `GET /actuator/health` — overall status + per-component detail (`200`/`503`)
- `GET /actuator/health/live` — liveness (always `UP`; wire to `livenessProbe`)
- `GET /actuator/health/ready` — readiness (aggregate; wire to `readinessProbe`)
- `GET /actuator/info` — static config + dynamic contributors
- `GET /actuator/metrics` — Prometheus default registry (needs `pico-actuator[metrics]`)

## Steps

1. **Add dependency** to `pyproject.toml`:
   ```toml
   "pico-actuator>=0.1.0",
   ```
   The endpoints appear with zero config — pico-boot auto-discovers the module.

2. **Optional config** in `application.yaml` (all fields have defaults):
   ```yaml
   actuator:
     show_components: true       # per-indicator detail in /health
     check_timeout_seconds: 5.0  # per-indicator time budget
     info:
       app: my-service
   ```

3. **Contribute a health indicator** — a `@component` satisfying the
   `HealthIndicator` protocol (`name` attr + `check()`); no registration:
   ```python
   from pico_ioc import component

   @component
   class DbHealth:
       name = "db"

       def __init__(self, engine: Engine):
           self.engine = engine

       def check(self):  # sync or async; dict or truthy
           self.engine.connect().close()
           return {"status": "UP"}
   ```
   Indicators run concurrently, each bounded by `check_timeout_seconds`. A
   raising or timed-out indicator reports its component `DOWN` — the endpoint
   never 500s.

4. **Contribute /info data** the same way with `contribute() -> dict`
   (`InfoContributor` protocol).

## Rules

- Keep `check()` cheap; cache expensive probes (indicators are singletons —
  store the last result + timestamp on `self`).
- Never point `livenessProbe` at `/health` or `/health/ready`: a slow
  dependency would restart healthy pods.
- Put only recoverable dependencies behind readiness (database, broker).
