---
title: "Incident — Find It in Seconds"
---

## What Is About to Happen

Your facilitator will switch the ArgoCD application to the `scenario/incident-latency` branch.
This deploys a version of `payment-mock` that introduces a 500ms artificial delay on every
payment call. No code was changed on the cluster directly — it is a Git branch switch, and
ArgoCD syncs it automatically.

Watch the Kiali graph as this happens.

---

## Watching the Incident

On the Kiali graph, observe the `checkout-api → payment-mock` edge:

- The edge colour shifts from **green → yellow → red** as error rate and latency climb
- The request rate stays the same — the load generator did not change
- Only the `checkout-api → payment-mock` edge is affected — every other edge stays green

This is how you distinguish a slow dependency from a failing service. The mesh tells you
exactly where the problem is before anyone has opened a log file.

---

## Exercise — Confirm the Latency in Your Terminal

```terminal:execute
command: kubectl get pods -n demo-app -l app=payment-mock
```

**Observe:** Both `payment-mock-v1` and `payment-mock-v2` pods are running. The incident
scenario routes traffic to v2, which has the latency injected.

---

## Find the Root Cause in Jaeger

Open the distributed tracing UI:

**Where**: `<NKP_BASE>/dkp/jaeger`

1. **Service**: select `frontend`
2. **Operation**: leave as `All`
3. Click **Find Traces**
4. Select a recent trace — look for ones with high duration (over 500ms)

**Expand the trace**:

```
frontend          [   50ms   ]
  └── catalog-api [ 10ms ]
  └── checkout-api [  530ms   ←── slow ]
        └── payment-mock-v2 [ 510ms ←── here ]
```

**Observe:** The trace shows exactly which span is slow — `payment-mock-v2`. The span is
highlighted red or yellow if duration exceeds the expected baseline.

Without distributed tracing, diagnosing this would require correlating logs across 4 services,
checking timestamps, and reasoning about which service introduced the latency. With Jaeger,
the answer is visible in the first trace you open.

---

## Rollback — One Git Change

Your facilitator will now switch ArgoCD back to `scenario/baseline`.

```
ArgoCD: targetRevision = scenario/baseline
```

Watch the Kiali graph recover:
- `checkout-api → payment-mock` edge returns to **green** within 30 seconds
- No kubectl apply was run. No pod was restarted manually. No config was edited directly.

The recovery path is the same as the deployment path: **change Git, the platform does the rest.**

---

## Exercise — Verify Recovery

```terminal:execute
command: kubectl get pods -n demo-app
```

**Observe:** All pods are `Running` with `2/2` containers. The rollback redeployed the
baseline version of payment-mock — a clean, healthy state.

---

## What This Means for Partners

A partner selling NKP can show customers:

1. **Zero-instrumentation observability** — existing apps get service topology and tracing on day 1
2. **Fast incident detection** — the mesh surfaces where the problem is, not just that there is a problem
3. **Safe rollback** — GitOps means rollback is always one commit away, with no manual steps

The combination of Istio + Kiali + Jaeger + ArgoCD, pre-assembled and supported by Nutanix,
is the answer to "how do we get observability without a six-month instrumentation project?"

---

## Session Complete

Your facilitator will set the scenario to `scenario/load-off` to end the demo cleanly.

What you have seen today:

| Module | Key takeaway |
|--------|-------------|
| Container fundamentals | Containers are tiny VMs — same isolation concept, 100x lighter |
| Kommander platform | Multi-cluster RBAC, policies, and add-ons managed from one place |
| Ecommerce on NKP | GitOps delivery + zero-instrumentation observability + instant incident trace |

**NKP is the platform that makes Kubernetes enterprise-ready on Nutanix infrastructure.**
