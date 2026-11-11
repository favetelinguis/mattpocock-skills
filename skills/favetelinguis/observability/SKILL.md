---
name: observability
description: "Observability reference for production-readiness-check's Production reviewer. Use when production-readiness-check calls it."
---

# Observability

Language-agnostic. Production behavior is answerable from outside the process only when the code ships its own signals. Event names, metric names, and span attributes follow the project's domain language (`GLOSSARY.md` when it exists).

## On-call questions

Every signal earns its place by answering one of 2 to 4 concrete questions an on-call engineer will ask when the feature or boundary degrades:

```text
Feature: checkout payment retry
On-call questions:
1. What fraction of payments succeed on the first attempt versus after retry?
2. When a payment fails permanently, which provider code or timeout caused it?
3. Is the payment provider slower than baseline right now?
```

Each question maps to the signal that answers it:

| Signal             | Answers                                                                         | Cost profile                                             |
| ------------------ | ------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Metric**         | **That** something is wrong (rate, error ratio, percentile latency, saturation) | Fixed per label combination; cheap to query and alert on |
| **Trace**          | **Where** time or failure went across services, queues, and DB calls            | Per-request; sampled                                     |
| **Structured log** | **Why** a specific execution took the path it did                               | Per-event; grows with traffic                            |

Instrumentation reuses the project's existing logger, metrics registry, and OpenTelemetry setup, and sits behind a middleware or module boundary so SDK calls stay out of domain code.

## Structured logs

Every log entry is as a structured JSON record with a stable `event` name and machine-readable fields.

- **Log levels carry operational meaning:**
  - `error`: invariant broken or unhandled failure; requires human investigation.
  - `warn`: degraded path handled automatically (retry succeeded, fallback used, rate limit waited).
  - `info`: state-changing business or lifecycle event (order placed, migration completed, worker started).
  - `debug`: high-volume diagnostic detail; disabled in production by default.
- **Correlation ID**: accept or generate a `requestId` / `correlationId` at the system boundary, bind it to a child logger, and propagate it across every HTTP call, queue message, and async worker.
- **Entry-point attribution**: when more than one caller writes to the same log sink (scheduler tick, HTTP replay endpoint, webhook, manual CLI run), stamp `entryPoint` where execution starts and propagate it beside `requestId` so on-call never has to guess which trigger produced a line.
- **Allowlist fields**: redact secrets, auth headers, tokens, passwords, and raw PII. Log sanitized identifiers, status codes, attempt counts, and durations instead of full request or response bodies.

## RED and USE metrics

- **Request-driven paths (endpoints, RPC handlers, outbound adapters)**: instrument **RED**:
  - **Rate**: requests per second.
  - **Errors**: failing requests per second, grouped by failure class.
  - **Duration**: latency **histogram** (never a bare average) exposing p50, p95, and p99.
- **Resource-driven paths (DB pools, worker queues, caches, runtime hosts)**: instrument **USE**:
  - **Utilization**: fraction of capacity busy.
  - **Saturation**: queued work or wait time beyond capacity (queue depth, oldest message age, pool wait count).
  - **Errors**: resource allocation or connection failures.
- **Guard label cardinality**: every unique label combination creates a separate time series. Restrict metric labels to small, bounded sets (`route="/api/orders/:id"`, `status_class="5xx"`, `provider="stripe"`, `queue="invoices"`). Put high-cardinality values (`userId`, `requestId`, `email`, raw URLs, raw error strings) in structured logs and trace attributes only.

## Distributed traces

- OpenTelemetry (or the repo's tracing SDK) initializes at process startup, before instrumented modules load.
- W3C trace context (`traceparent`, `tracestate`) across every inbound and outbound HTTP call, RPC, and queue message header propagates across services, so traces stay unbroken.
- Manual spans wrap only meaningful internal units of work or external boundary adapters, and carry the bounded attributes on-call filters by.

## Alerts and runbooks

- **Page on user-visible symptoms**, such as elevated error rate, high p99 latency, or growing queue age. Keep cause signals (CPU, memory, single pod restart) on dashboards rather than pagers.
- **Use two severities only**: `page` (user-facing impact, act now) and `ticket` (degradation or capacity trend, act this week).
- **Link every alert to a runbook** in `docs/runbooks/` (or the repo's runbook path) answering three questions in as few lines as possible: what the alert means, the first query or command to run, and who to escalate to.

Every alert is symptom-based, justified by an SLO or baseline threshold, and paired with a runbook.

Code patterns, histogram bucket defaults, OpenTelemetry propagation snippets, and runbook templates are in [references/signals-and-alerts.md](references/signals-and-alerts.md).

## Verification checklist

Telemetry is code and fails silently when unverified.

- [ ] Every log event, metric, and span maps to an on-call question.
- [ ] Both the happy path and an error path have been exercised in tests or a local/staging run.
- [ ] Log output is valid JSON with stable `event` names, populated `requestId` and `entryPoint`, only allowlisted fields, and no `[object Object]` or leaked secrets.
- [ ] Every new endpoint, outbound dependency, and queue/pool exposes RED or USE metrics with histogram latency and bounded labels.
- [ ] Trace context crosses every service and queue boundary without orphaned spans.
- [ ] Checks that need a live collector or dashboard are listed as exact post-deploy log, metric, and trace queries.
