---
title: "Lab 2: GitOps App Deployment with Flux (20 min)"
---

## Goal

Deploy a real multi-service ecommerce application to `workload01` using **Flux CD** — NKP's
built-in GitOps engine. No pipelines, no manual apply. Three commands and your app is running.

---

## The App — otel-shop

The app you're deploying is a microservices ecommerce store with four services:

```
Browser → frontend → catalog-api    (product listings)
                   → checkout-api → payment-mock  (order + payment)
```

| Service | Role |
|---------|------|
| `frontend` | Web UI — product catalog and checkout flow |
| `catalog-api` | Returns product listings |
| `checkout-api` | Handles orders, calls payment-mock |
| `payment-mock` | Simulates payment processing |

All four are deployed together from a single Git commit — no manual steps per service.

> **Your session namespace:** `bls-app-$(session_name)` — every attendee gets isolated
> resources on the shared cluster.

---

## Step 1 — Create Your Namespace

```execute
kubectl create namespace bls-app-$(session_name)
```

---

## Step 2 — Create a GitRepository Source

Point Flux at the public workshop GitHub repo (the app manifests live inside it):

```execute
cat > ~/gitrepo.yaml << EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: bls-app-source-$(session_name)
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://github.com/icediceice/Nutanix-NKP-Workshop
  ref:
    branch: main
EOF
kubectl apply -f ~/gitrepo.yaml
```

Check Flux can reach the repo (~15 seconds):

```execute
kubectl get gitrepository -n flux-system bls-app-source-$(session_name)
```

Expected: `READY=True`

---

## Step 3 — Deploy with a Kustomization

Tell Flux to apply the otel-shop manifests into your namespace:

```execute
cat > ~/kustomization.yaml << EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: bls-app-$(session_name)
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./workshops/bls-workshop/apps/otel-shop
  prune: true
  sourceRef:
    kind: GitRepository
    name: bls-app-source-$(session_name)
  targetNamespace: bls-app-$(session_name)
EOF
kubectl apply -f ~/kustomization.yaml
```

Watch all four services come up (~60 seconds):

```execute
kubectl get pods -n bls-app-$(session_name) -w
```

Press `Ctrl+C` when all pods show `Running`.

> **Checkpoint ✅** — 4 pods Running: `frontend`, `catalog-api`, `checkout-api`, `payment-mock`.

---

## Step 4 — Explore the Deployment

See everything Flux deployed in a single command:

```execute
kubectl get all -n bls-app-$(session_name)
```

You'll see 4 Deployments, 4 Services — all created from one `Kustomization` pointing at a
path in a GitHub repo. No `kubectl apply` was run for any individual resource.

Check the inter-service wiring:

```execute
kubectl describe deployment frontend -n bls-app-$(session_name)
```

Note the `CATALOG_URL` and `CHECKOUT_URL` env vars — the frontend knows where to find the
other services in the same namespace.

---

## Step 5 — View in Kommander

1. Click **<a href="https://kommander.nkp.nuth-lab.xyz" target="_blank">Open Kommander ↗</a>**.
2. In the left navigation go to **Continuous Delivery**.
3. Select **GitRepositories** — find `bls-app-source-$(session_name)` with `READY=True`.
4. Select **Kustomizations** — find `bls-app-$(session_name)` showing the applied revision,
   last reconcile time, and the 8 resources it manages.

Every service on this cluster is sourced from Git. No snowflake deployments.

---

## Step 6 — Self-Healing Demo

Delete the entire frontend — Flux will restore it automatically:

```execute
kubectl delete deployment frontend -n bls-app-$(session_name)
```

Confirm it's gone:

```execute
kubectl get pods -n bls-app-$(session_name)
```

Watch Flux restore it (within 5 minutes — the reconciliation interval):

```execute
kubectl get pods -n bls-app-$(session_name) -w
```

Press `Ctrl+C` when the frontend pod is `Running` again.

> **This is declarative GitOps** — the cluster always converges back to what Git declares.
> No manual intervention needed, no configuration drift.
