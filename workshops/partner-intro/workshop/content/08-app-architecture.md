---
title: "The Demo App — Rx Storefront"
---

## What We Are Running

The application running on this NKP cluster is **Rx Storefront** — a 4-service ecommerce
application that exercises the platform's key capabilities: service mesh, observability,
GitOps delivery, and resource governance.

This is the kind of application a partner's customer would run on NKP. Not a toy — a real
microservices architecture with real traffic patterns.

---

## Service Architecture

```
                    ┌─────────────────────────────────────┐
                    │           demo-app namespace          │
                    │                                       │
Browser ──────────► │  frontend (Flask + nginx)             │
                    │     │              │                  │
                    │     ▼              ▼                  │
                    │  catalog-api    checkout-api          │
                    │  (Python/Flask) (Python/Flask)        │
                    │                   │                   │
                    │                   ▼                   │
                    │            payment-mock               │
                    │            (simulated payment)        │
                    └─────────────────────────────────────┘
                              ↕ Istio sidecar on every pod
```

---

## The Four Services

| Service | Tech | Role |
|---------|------|------|
| **frontend** | Python Flask + nginx | Browser-facing UI. Calls catalog-api for product listings and checkout-api for cart operations. |
| **catalog-api** | Python Flask | Returns product listings. Backed by in-memory data — no database dependency for this demo. |
| **checkout-api** | Python Flask | Handles cart and order submission. Calls payment-mock to process payment. |
| **payment-mock** | Python Flask | Simulates a payment processor. Has two versions (v1, v2) for the canary demo. |

---

## What Istio Adds

Every pod in `demo-app` has an **Istio sidecar** — a proxy container running alongside the
application container. The sidecar intercepts all inbound and outbound traffic without any
changes to the application code.

This gives us for free:
- **mTLS** — all service-to-service communication is encrypted and authenticated
- **Traffic metrics** — request rate, error rate, and latency for every call
- **Distributed tracing** — every request gets a trace ID propagated through all services
- **Traffic control** — split traffic between versions (canary), inject faults, mirror traffic

The application code knows nothing about Istio. The platform provides observability automatically.

---

## Exercise — See the Running Services

```terminal:execute
command: kubectl get pods -n demo-app -o wide
```

**Observe:**
- `READY` column shows `2/2` for each pod — that is the app container + the Istio sidecar
- `NODE` column shows which VM each pod landed on — Kubernetes scheduled them automatically

```terminal:execute
command: kubectl get svc -n demo-app
```

**Observe:** Each service has a `ClusterIP` — a stable virtual IP that does not change even
if pods restart. The `frontend` service has an external IP from MetalLB, which is how the
browser reaches it.

---

## The Current Scenario

The application is running on the `scenario/baseline` branch — 100% of traffic going to
payment-mock **v1**. The load generator is producing steady traffic so the observability
tools have data to show.

In the next section you will open the live application and then watch Kiali map every
service call in real time.
