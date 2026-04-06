---
title: "Live App and Service Mesh Topology"
---

## Open the Storefront

The frontend URL is shown on the Demo Wall under **Application Access → Storefront**.

Open it in your browser. You will see the Rx Storefront — product listings, a cart, a checkout
flow. Behind every page load, the frontend calls catalog-api and checkout-api, which calls
payment-mock. Each of those calls is tracked by Istio.

---

## Exercise — Inspect the Frontend Service

```terminal:execute
command: kubectl get svc frontend -n demo-app
```

**Observe:** The `EXTERNAL-IP` column shows the MetalLB IP that routes browser traffic into
the cluster. Copy this IP and open it in your browser if the Demo Wall link is not available.

---

## Open Kiali — The Service Mesh Map

Kiali is the service mesh observability UI for Istio. It is accessible through the NKP console
single-sign-on — no separate login.

**Where**: `<NKP_BASE>/dkp/kiali`

*(Your facilitator will project this. Follow along.)*

---

## What Kiali Shows

Once Kiali loads:

1. Select **Graph** in the left sidebar
2. Select namespace: `demo-app`
3. Set the time range to **Last 1 minute**

**What you will see**: A live topology graph of every service-to-service call currently
happening in the namespace. Arrows show traffic direction. Edge labels show request rate.
Node colours show health.

```
browser ──► frontend ──► catalog-api
                    └──► checkout-api ──► payment-mock-v1
```

---

## Reading the Graph

| Colour | Meaning |
|--------|---------|
| Green | Healthy — error rate below threshold |
| Yellow | Degraded — elevated error rate or latency |
| Red | Critical — high error rate or service unreachable |
| Blue | No health data (too little traffic or new service) |

Click any **edge** (the arrow between two services) to see:
- Request rate (requests/second)
- Error rate (% of 5xx responses)
- P50 / P90 / P99 latency

Click any **node** (a service) to see its health summary, workload name, and pods.

---

## Exercise — Check Traffic in Your Terminal

While Kiali shows the topology visually, you can see the same data via kubectl:

```terminal:execute
command: kubectl top pods -n demo-app
```

**Observe:** Live CPU and memory usage for every pod. The load generator is producing steady
traffic, so all pods show active CPU consumption.

---

## The Key Point

Kiali built this entire service map with **zero application code changes**. There is no
tracing SDK in the application. No custom metrics endpoint. The Istio sidecar on each pod
captures every call and reports it automatically.

This is what "zero instrumentation observability" means in practice. A partner's customer
can onboard an existing application to NKP and immediately get this topology map — without
touching the app.

---

## Next

Your facilitator will now trigger a latency incident. Watch what happens to the graph.
