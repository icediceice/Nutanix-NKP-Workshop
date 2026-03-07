# Lab 2 — Observability

## Overview
- **Duration**: 45–60 min
- **What you'll do**: Explore the three pillars of observability — live mesh topology (Kiali), distributed tracing (Jaeger), and metrics dashboards (Grafana) — all without changing a line of application code.

## Before You Begin
- Verify: Demo Wall shows "lab-02-start — Full storefront running"
- Verify: Kiali graph shows traffic flowing between all 4 services
- Current scenario: Full storefront + baseline load (2 RPS frontend, 0.5 RPS checkout)

---

## Exercise 2.1: Live Topology — Explore Kiali (10 min)

### What You'll Do
Use Kiali's service graph to understand the live traffic topology and identify service health at a glance.

### Steps

1. Open **Kiali** → Graph → Namespace: `demo-app`

2. Set display options:
   - Enable: Request Rate, Response Time, Traffic Animation

3. Click the edge between `checkout-api` → `payment-mock-v1`:
   - View request rate, P50/P99 latency, error rate

4. Click the `frontend` node:
   - View inbound/outbound traffic summary

5. Switch graph types: App graph → Versioned app graph → Workload graph

### Checkpoint ✅
- [ ] Graph shows 4 services with traffic flowing
- [ ] All edges are green (no errors)
- [ ] Request rate is visible on edges (~2 RPS frontend, ~0.5 RPS checkout)

---

## Exercise 2.2: Distributed Tracing — Follow a Request through Jaeger (15 min)

### What You'll Do
Generate a checkout request and follow it through the distributed trace to see every service involved.

### Steps

1. Generate a manual checkout (or click Checkout in the browser):
   ```bash
   curl -X POST http://<STOREFRONT_IP>/api/checkout \
     -H "Content-Type: application/json" \
     -d '{"items": [{"id": "1", "qty": 1}]}'
   ```

2. In **Storefront**: Click Checkout → Note the "Last Trace" badge → Copy the trace ID

3. In **Jaeger**: Search by Service: `frontend`, or paste the trace ID directly

4. Open the trace → Expand the span waterfall:
   - `frontend` (root span)
   - `checkout-api` (child span)
   - `payment-mock-v1` (child span)
   - Each span shows duration, service name, operation name

5. Alternative: Find recent traces via Jaeger API:
   ```bash
   curl "http://<JAEGER_URL>/api/traces?service=frontend&limit=5" | jq '.data[0].traceID'
   ```

### Checkpoint ✅
- [ ] Trace shows 3+ spans across 3 services
- [ ] Total trace duration is ~50–200ms (healthy baseline)
- [ ] Each span has the correct service name and operation

---

## Exercise 2.3: Log Correlation — Trace ID to Logs (10 min)

### What You'll Do
Use the trace ID from Jaeger to find correlated log lines across multiple services simultaneously.

### Steps

1. Copy a trace ID from Jaeger (or from the storefront's "Last Trace" badge):
   ```bash
   TRACE_ID="<paste trace ID here>"
   ```

2. Find matching logs across services:
   ```bash
   kubectl -n demo-app logs -l app=checkout-api --tail=100 | grep "$TRACE_ID"
   kubectl -n demo-app logs -l app=payment-mock --tail=100 | grep "$TRACE_ID"
   ```

3. If Grafana/Loki is available:
   ```
   {namespace="demo-app"} |= "<TRACE_ID>"
   ```

### Checkpoint ✅
- [ ] Log lines from `checkout-api` and `payment-mock` contain the same trace ID
- [ ] Each log line includes `trace_id` and `span_id` JSON fields

---

## Exercise 2.4 (Bonus): Grafana Dashboards (10 min)

1. Open **Grafana** → Dashboards → Istio Mesh Dashboard
2. Filter by namespace: `demo-app`
3. View: Request rate, error rate, request duration (P50, P99)
4. Explore: Istio Service Dashboard → select `payment-mock-v1`

**Bonus**: Switch load profile to peak and watch the graphs update:
```bash
./scripts/switch-lab.sh lab-02-high-load
```

---

## Cleanup
To reset this lab:
```bash
./scripts/switch-lab.sh lab-02-start
```

---

## Key Takeaways
- Istio sidecar proxies emit telemetry (metrics, traces, logs) automatically — no SDK instrumentation required for topology and traffic metrics.
- A single trace ID links a request across all services, from frontend → checkout-api → payment-mock, enabling instant root-cause analysis.
- The three pillars work together: Kiali for topology, Jaeger for traces, Grafana for time-series metrics.
