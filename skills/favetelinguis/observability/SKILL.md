---
name: observability
description: "Instrument production code with structured logging, RED and USE metrics, OpenTelemetry tracing, symptom-based alerts, and runbooks. Use when adding or reviewing endpoints, background jobs, queues, external integrations, or infrastructure health signals, when designing telemetry in a spec, or when converting temporary debug probes into permanent observability."
---

# Observability

Language-agnostic. Instrument code alongside the feature so production behavior is answerable from outside the process.

When exploring the codebase, read `GLOSSARY.md` (if it exists) so event names, metric names, and span attributes match the project's domain language, and respect ADRs in the area you're touching.

## Process

### 1. Write the on-call questions

Before adding any signal, write 2 to 4 concrete questions an on-call engineer will ask when this feature or boundary degrades:

```text
Feature: checkout payment retry
On-call questions:
1. What fraction of payments succeed on the first attempt versus after retry?
2. When a payment fails permanently, which provider code or timeout caused it?
3. Is the payment provider slower than baseline right now?
```

Map each question to the signal that answers it:

| Signal             | Answers                                                                         | Cost profile                                             |
| ------------------ | ------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Metric**         | **That** something is wrong (rate, error ratio, percentile latency, saturation) | Fixed per label combination; cheap to query and alert on |
| **Trace**          | **Where** time or failure went across services, queues, and DB calls            | Per-request; sampled                                     |
| **Structured log** | **Why** a specific execution took the path it did                               | Per-event; grows with traffic                            |

Reuse the project's existing logger, metrics registry, and OpenTelemetry setup before introducing new libraries. When designing a new logging or telemetry seam, call the Skill tool with "codebase-design" so instrumentation sits behind a deep module or middleware boundary rather than leaking SDK calls across domain code.

**Done when:** 2 to 4 on-call questions are written down and every planned log event, metric, and span maps to at least one question.

### 2. Emit structured logs with correlation and entry-point attribution

Write every log entry as a structured JSON record with a stable `event` name and machine-readable fields, never prose interpolation.

- **Log levels carry operational meaning:**
  - `error`: invariant broken or unhandled failure; requires human investigation.
  - `warn`: degraded path handled automatically (retry succeeded, fallback used, rate limit waited).
  - `info`: state-changing business or lifecycle event (order placed, migration completed, worker started).
  - `debug`: high-volume diagnostic detail; disabled in production by default.
- **Correlation ID**: accept or generate a `requestId` / `correlationId` at the system boundary, bind it to a child logger, and propagate it across every HTTP call, queue message, and async worker.
- **Entry-point attribution**: when more than one caller writes to the same log sink (scheduler tick, HTTP replay endpoint, webhook, manual CLI run), stamp `entryPoint` where execution starts and propagate it beside `requestId` so on-call never has to guess which trigger produced a line.
- **Allowlist fields**: redact secrets, auth headers, tokens, passwords, and raw PII. Log sanitized identifiers, status codes, attempt counts, and durations instead of full request or response bodies.

**Done when:** every new log statement emits a stable `event` key, carries `requestId` and `entryPoint` across async boundaries, and logs only allowlisted fields.

### 3. Instrument RED and USE metrics with bounded cardinality

- **Request-driven paths (endpoints, RPC handlers, outbound adapters)**: instrument **RED**:
  - **Rate**: requests per second.
  - **Errors**: failing requests per second, grouped by failure class.
  - **Duration**: latency **histogram** (never a bare average) exposing p50, p95, and p99.
- **Resource-driven paths (DB pools, worker queues, caches, runtime hosts)**: instrument **USE**:
  - **Utilization**: fraction of capacity busy.
  - **Saturation**: queued work or wait time beyond capacity (queue depth, oldest message age, pool wait count).
  - **Errors**: resource allocation or connection failures.
- **Guard label cardinality**: every unique label combination creates a separate time series. Restrict metric labels to small, bounded sets (`route="/api/orders/:id"`, `status_class="5xx"`, `provider="stripe"`, `queue="invoices"`). Put high-cardinality values (`userId`, `requestId`, `email`, raw URLs, raw error strings) in structured logs and trace attributes only.

**Done when:** every new endpoint, outbound dependency, and queue/pool exposes RED or USE metrics with histogram latency and strictly bounded labels.

### 4. Propagate distributed traces

- Initialize OpenTelemetry (or the repo's tracing SDK) at process startup before importing instrumented modules.
- Propagate W3C trace context (`traceparent`, `tracestate`) across every inbound and outbound HTTP call, RPC, and queue message header so traces stay unbroken across services.
- Add manual spans only around meaningful internal units of work or external boundary adapters, attaching the bounded attributes on-call filters by.

**Done when:** trace context crosses every service and queue boundary touched by the change without orphaned spans.

### 5. Configure symptom-based alerts and runbooks

When the change introduces or modifies alerting or production health gates:

- **Page on user-visible symptoms**, such as elevated error rate, high p99 latency, or growing queue age. Keep cause signals (CPU, memory, single pod restart) on dashboards rather than pagers.
- **Use two severities only**: `page` (user-facing impact, act now) and `ticket` (degradation or capacity trend, act this week).
- **Link every alert to a runbook** in `docs/runbooks/` (or the repo's runbook path) answering three questions in as few lines as possible: what the alert means, the first query or command to run, and who to escalate to.

Read [references/signals-and-alerts.md](references/signals-and-alerts.md) for code patterns, histogram bucket defaults, OpenTelemetry propagation snippets, and runbook templates when implementing any item above.

**Done when:** every alert is symptom-based, justified by an SLO or baseline threshold, and paired with a runbook.

### 6. Verify the telemetry

Telemetry is code and fails silently when unverified.

- Trigger both the happy path and an error path in tests or a local/staging run.
- Inspect the emitted log output to confirm valid JSON, stable `event` names, populated `requestId` and `entryPoint`, and no `[object Object]` or leaked secrets.
- Confirm metric series register with bounded labels and histogram buckets record observations.
- When infrastructure or collector pipelines live outside local tests, record the exact post-deploy log query, metric query, and trace check for the pull request.

**Done when:** emitted telemetry has been inspected on a real or simulated failure path, and any collector or dashboard checks that require a live environment are listed for post-deploy verification.
