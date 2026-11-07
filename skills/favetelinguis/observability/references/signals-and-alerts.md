# Signals, Cardinality, and Runbook Reference

Contents: Structured logging, RED and USE metrics, OpenTelemetry context propagation, Symptom-based alerting and runbooks, Pre-launch telemetry checklist.

## Structured logging

Bind `requestId` and `entryPoint` at the boundary where work enters the process and pass the child logger down:

```typescript
export type EntryPoint = 'http' | 'scheduler' | 'webhook' | 'replay_cli' | 'queue_worker';

export function createRunLogger(baseLogger: Logger, entryPoint: EntryPoint, requestId: string) {
  return baseLogger.child({ entryPoint, requestId });
}

// Structured event log: stable event key, bounded context, sanitized error metadata
log.warn(
  {
    event: 'payment_attempt_failed',
    paymentId,
    provider: 'stripe',
    errorCode: err.code,
    attempt,
    durationMs,
  },
  'payment attempt failed',
);
```

When propagating work onto a queue or background job, serialize `{ requestId, entryPoint, traceparent }` in the message metadata and rehydrate the child logger in the worker.

## RED and USE metrics

### RED (Request-driven endpoints and external adapters)

- `http_request_duration_seconds` (Histogram): labels `method`, `route`, `status_class` (`2xx`, `4xx`, `5xx`).
- `external_call_duration_seconds` (Histogram): labels `provider`, `operation`, `outcome` (`success`, `timeout`, `rate_limited`, `server_error`, `client_error`).
- Typical latency buckets (seconds): `[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]`.

### USE (Resources: queues, pools, workers)

- **Utilization**: `db_pool_active_connections / db_pool_max_connections`, worker busy slots.
- **Saturation**: `queue_depth`, `queue_oldest_message_age_seconds`, `db_pool_waiting_requests`.
- **Errors**: `db_pool_acquire_timeout_total`, `queue_dead_letter_total`.

### Label cardinality rules

| Safe as metric label | Put in logs / traces instead |
|---|---|
| `route="/api/orders/:id"` (template) | `/api/orders/9f8a-42c1` (raw path) |
| `status_class="5xx"` | Raw error message or stack trace |
| `provider="stripe"`, `operation="charge"` | `userId`, `tenantId`, `email`, `requestId` |
| `queue="invoice_generation"` | Job payload ID or webhook event ID |

## OpenTelemetry context propagation

Across queues or custom transports where auto-instrumentation does not inject headers automatically, inject and extract the active context explicitly:

```typescript
import { context, propagation, trace } from '@opentelemetry/api';

// Producer: inject active trace context into message headers
const headers: Record<string, string> = {};
propagation.inject(context.active(), headers);

// Consumer: extract trace context before running handler span
const parentCtx = propagation.extract(context.active(), message.headers);
await context.with(parentCtx, async () => {
  const span = trace.getTracer('worker').startSpan('process_invoice_job', {
    attributes: { 'job.entry_point': message.entryPoint, 'job.attempt': message.attempt },
  });
  try {
    await handleJob(message);
  } catch (err) {
    span.recordException(err as Error);
    throw err;
  } finally {
    span.end();
  }
});
```

## Symptom-based alerting and runbooks

| Alert on symptoms (page) | Keep on dashboards (cause) |
|---|---|
| 5xx error rate > 1% over 5m | Single pod CPU > 85% |
| Endpoint p99 latency > 2s over 10m | One container restart |
| Queue oldest message age > 10m | Disk usage at 70% |
| Dead-letter queue count > 0 | Cache hit ratio dip |

### Minimum viable runbook template (`docs/runbooks/<alert-slug>.md`)

```markdown
# Runbook: <Alert Name>

**Means:** <User-visible impact and top 1-2 likely causes>
**First check:**
1. Logs: `event:"<event_name>" AND level:error` grouped by `errorCode` and `entryPoint`
2. Metrics / State: `<exact query or CLI check, e.g. kubectl get pods / SQL pool query>`
**Mitigation:** <Rollback command, feature flag toggle, or scaling action>
**Escalate to:** <Team or on-call rotation>
```

## Pre-launch telemetry checklist

- [ ] 2 to 4 on-call questions are documented and mapped to signals.
- [ ] Structured JSON logs include `event`, `requestId`, and `entryPoint`.
- [ ] Zero secrets, tokens, or raw PII appear in log fields or span attributes.
- [ ] RED histograms cover every new endpoint and external call with bounded labels.
- [ ] USE gauges/counters cover any new queue, pool, or stateful worker.
- [ ] Trace context is propagated across HTTP and async queue boundaries.
- [ ] Every new alert is symptom-based and links to a runbook.
