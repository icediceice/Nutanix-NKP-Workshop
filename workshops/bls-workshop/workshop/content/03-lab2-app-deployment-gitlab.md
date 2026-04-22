---
title: "Lab 2: GitOps App Deployment with Flux (20 min)"
---

## Goal

Deploy a real application to `workload01` using **Flux CD** — NKP's built-in GitOps engine —
pointed at a public GitHub repository. No credentials, no pipelines, no manual apply.
Three commands and your app is running.

---

## Background

NKP ships **Flux CD** as its native GitOps engine. Flux watches a Git repository and
continuously reconciles the cluster to match what is declared there — automatically.

Two Flux resources drive every deployment:

| Resource | Purpose |
|----------|---------|
| `GitRepository` | Points Flux at a Git repo (URL + branch) |
| `Kustomization` | Tells Flux which path in that repo to apply and to which namespace |

> **Your session namespace:** `bls-app-$(session_name)` — every attendee gets an isolated
> namespace on the shared cluster so your resources never conflict with others.

---

## Step 1 — Create Your Namespace

```execute
kubectl create namespace bls-app-$(session_name)
```

---

## Step 2 — Create a GitRepository Source

Point Flux at the public **podinfo** GitHub repo — a lightweight Go web app built for
exactly this kind of demo:

```execute
cat > ~/gitrepo.yaml << EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: bls-app-source-$(session_name)
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://github.com/stefanprodan/podinfo
  ref:
    branch: master
EOF
kubectl apply -f ~/gitrepo.yaml
```

Check Flux can reach the repo (~15 seconds):

```execute
kubectl get gitrepository -n flux-system bls-app-source-$(session_name)
```

Expected: `READY=True`, `STATUS=stored artifact for revision 'master/...'`

---

## Step 3 — Deploy with a Kustomization

Tell Flux to apply the `./kustomize` path from that repo into your namespace:

```execute
cat > ~/kustomization.yaml << EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: bls-app-$(session_name)
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./kustomize
  prune: true
  sourceRef:
    kind: GitRepository
    name: bls-app-source-$(session_name)
  targetNamespace: bls-app-$(session_name)
EOF
kubectl apply -f ~/kustomization.yaml
```

Watch the pods come up (~30 seconds):

```execute
kubectl get pods -n bls-app-$(session_name) -w
```

Press `Ctrl+C` when you see the pod in `Running` state.

> **Checkpoint ✅** — podinfo pod is Running in `bls-app-$(session_name)`.

---

## Step 4 — Explore the Deployment

Check what Flux deployed into your namespace:

```execute
kubectl get all -n bls-app-$(session_name)
```

You'll see a Deployment, ReplicaSet, Pod, Service, and HorizontalPodAutoscaler — all
created from a single `Kustomization` object pointing at a GitHub repo.

Describe the podinfo service to see its configuration:

```execute
kubectl describe svc podinfo -n bls-app-$(session_name)
```

---

## Step 5 — View in Kommander

1. Click **<a href="https://kommander.nkp.nuth-lab.xyz" target="_blank">Open Kommander ↗</a>**.
2. In the left navigation go to **Continuous Delivery**.
3. Select **GitRepositories** — find `bls-app-source-$(session_name)` with `READY=True`.
4. Select **Kustomizations** — find `bls-app-$(session_name)` showing the applied revision and last reconcile time.

This is the GitOps view — every application on this cluster is managed from Git, not from someone's terminal.

---

## Step 6 — Self-Healing Demo

This is the key Flux behaviour: the cluster always converges back to what Git declares.

Delete the deployment manually:

```execute
kubectl delete deployment -n bls-app-$(session_name) podinfo
```

Confirm it's gone:

```execute
kubectl get pods -n bls-app-$(session_name)
```

Now watch Flux restore it automatically (within 5 minutes — the reconciliation interval):

```execute
kubectl get pods -n bls-app-$(session_name) -w
```

Press `Ctrl+C` when the pod is `Running` again.

> **This is declarative GitOps** — nobody can permanently delete an app by accident.
> The cluster always reconciles back to the source of truth in Git.
