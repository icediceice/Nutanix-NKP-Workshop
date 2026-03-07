# Lab 5 — Production Operations

## Overview
- **Duration**: 45–60 min
- **What you'll do**: Diagnose and resolve production incidents using distributed tracing, test node failure resilience with PodDisruptionBudgets, and configure KEDA event-driven autoscaling.

## Before You Begin
- Verify: Demo Wall shows "lab-05-start — Healthy 90/10 canary"
- Verify: Both `payment-mock-v1` and `payment-mock-v2` pods are running
- Current scenario: 90% v1 / 10% v2 canary, no fault injection

---

## Exercise 5.1: Incident — Latency Injection (10 min)

### What You'll Do
Inject 1-second latency into v2 and use Jaeger distributed tracing to identify the root cause.

### Steps

1. Trigger the latency incident:
   ```bash
   ./scripts/switch-lab.sh lab-05-incident-latency
   ```

2. In **Storefront**: Click Checkout 3 times. Feel the slowness (~1s per checkout on v2 requests).

3. Note the "Last Trace" badge → copy the trace ID.

4. In **Jaeger**: Open the trace → Expand span waterfall:
   - `frontend` → `checkout-api` → `payment-mock-v2`
   - The `payment-mock-v2` span shows ~1000ms duration
   - All other spans are normal (~10–50ms)
   - **Root cause identified**: v2 is adding the latency

5. Alternative: Find slow traces via API:
   ```bash
   curl "http://<JAEGER_URL>/api/traces?service=payment-mock&minDuration=800ms&limit=5"
   ```

### Checkpoint ✅
- [ ] Trace shows `payment-mock-v2` span with ~1000ms duration
- [ ] Other spans (frontend, checkout-api, payment-mock-v1) are normal

---

## Exercise 5.2: Incident — Error Injection (10 min)

### What You'll Do
Switch to a 10% error rate on v2 and identify it via Kiali's visual error indicators.

### Steps

1. Switch to error incident:
   ```bash
   ./scripts/switch-lab.sh lab-05-incident-error
   ```

2. In **Kiali** → Graph: Watch for **red edges** on `payment-mock-v2` (error rate label visible)

3. In **Jaeger**: Filter by tag `error=true` → See failed spans from v2

4. In **Storefront**: ~1 in 10 checkouts fails with an error

5. In **Demo Wall**: Policy compliance card shows elevated error count

### Checkpoint ✅
- [ ] Kiali shows red error edges on the v2 path
- [ ] Jaeger shows error traces with 500 status from v2
- [ ] Approximately 10% of checkout attempts fail

---

## Exercise 5.3: Node Failure Resilience (10 min)

### What You'll Do
Enable high-availability mode with PodDisruptionBudgets and anti-affinity, then drain a node to verify the application survives.

### Steps

1. Enable resilience mode:
   ```bash
   ./scripts/switch-lab.sh lab-05-node-resilience
   ```

2. Verify pods are spread across nodes:
   ```bash
   kubectl -n demo-app get pods -o wide
   # Expect pods on multiple nodes
   ```

3. Pick a worker node to drain:
   ```bash
   NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane!= \
     -o jsonpath='{.items[0].metadata.name}')
   echo "Draining node: $NODE"
   ```

4. Drain the node:
   ```bash
   kubectl cordon "$NODE"
   kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data
   ```

5. Watch pods reschedule (application stays up!):
   ```bash
   kubectl -n demo-app get pods -o wide -w
   ```

6. Verify storefront is still accessible:
   ```bash
   curl -s http://<STOREFRONT_IP>/ | head -5
   # Expected: HTML response — app is still serving traffic
   ```

7. Uncordon when done:
   ```bash
   kubectl uncordon "$NODE"
   ```

### Checkpoint ✅
- [ ] Storefront remains accessible throughout the drain
- [ ] Pods reschedule to surviving nodes
- [ ] PDBs prevent more than 1 replica being unavailable at a time

---

## Exercise 5.4: KEDA Autoscaling (10 min)

### What You'll Do
Enable KEDA event-driven autoscaling for checkout-api. Watch it scale from zero when traffic arrives.

### Steps

1. Enable KEDA:
   ```bash
   ./scripts/switch-lab.sh lab-05-keda
   ```

2. Watch checkout-api replicas:
   ```bash
   kubectl -n demo-app get deploy checkout-api -w
   # Starts at 0. KEDA detects baseline traffic and scales up within ~30s.
   ```

3. Inspect the ScaledObject:
   ```bash
   kubectl -n demo-app describe scaledobject checkout-api-v1-keda
   ```

4. In **Demo Wall**: Autoscaler card shows ScaledObject active status.

### Checkpoint ✅
- [ ] `checkout-api` scales from 0 to 1+ replicas
- [ ] ScaledObject shows Active status
- [ ] Storefront checkout still works after scale-up

---

## Exercise 5.5: Recovery (5 min)

Reset all incidents and restore healthy baseline:
```bash
./scripts/switch-lab.sh lab-05-start
```

All fault injection cleared. 90/10 canary restored. Application healthy.

---

## Cleanup
To reset this lab:
```bash
./scripts/switch-lab.sh lab-05-start
```

---

## Key Takeaways
- Distributed tracing pinpoints root cause in seconds — you can see exactly which service and which version introduced the problem.
- PodDisruptionBudgets are a platform contract: "At least N replicas must be running before you can evict pods." Node maintenance becomes safe without manual coordination.
- KEDA scales on real signals (request rate, queue depth, custom metrics) — not just CPU. Scale-to-zero eliminates idle resource waste.
