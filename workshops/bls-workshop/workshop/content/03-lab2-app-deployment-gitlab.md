---
title: "Lab 2: Application Deployment via NKP + GitLab (45 min)"
---

## Goal

Deploy an application to `workload01` using **FluxCD GitOps** — NKP's built-in continuous delivery
engine — connected to a GitLab repository. Any push to the repo will automatically reconcile
the cluster state.

---

## Background

NKP ships **Flux CD** as its native GitOps engine. Flux watches a Git repository and
continuously reconciles the cluster to match what is declared in that repo.

Two Flux resources drive this:

| Resource | Purpose |
|----------|---------| 
| `GitRepository` | Points Flux at a Git repo (URL + credentials) |
| `Kustomization` | Tells Flux which path in that repo to apply, and to which cluster |

---

## Step 1 — Prepare

Get the GitLab repository URL and a **read-only personal access token** from your facilitator.

Create the application namespace:

```execute
kubectl create namespace bls-app
```

---

## Step 2 — Create a GitLab Credentials Secret

Flux needs credentials to pull from a private GitLab repo. Set your token first (replace `YOUR_TOKEN` with the value from your facilitator):

```execute
export GITLAB_TOKEN=YOUR_TOKEN
```

Then create the secret:

```execute
kubectl create secret generic gitlab-credentials \
  --namespace flux-system \
  --from-literal=username=workshop-user \
  --from-literal=password=${GITLAB_TOKEN}
```

---

## Step 3 — Create a GitRepository Source

Create a `GitRepository` object pointing Flux at the GitLab repo.
Replace `<gitlab-url>` with the URL your facilitator provided:

```execute
cat > ~/gitrepo.yaml << 'EOF'
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: bls-app-source
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://YOUR_GITLAB_URL/workshop/sample-app.git
  secretRef:
    name: gitlab-credentials
  ref:
    branch: main
EOF
```

```execute
kubectl apply -f ~/gitrepo.yaml
```

Verify Flux can reach the repo:

```execute
kubectl get gitrepository -n flux-system bls-app-source
```

Expected: `READY=True`, `STATUS=stored artifact for revision 'main/...'`

---

## Step 4 — Create a Kustomization

Tell Flux which path to apply to which namespace:

```execute
cat > ~/kustomization.yaml << 'EOF'
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: bls-app
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./apps/nginx
  prune: true
  sourceRef:
    kind: GitRepository
    name: bls-app-source
  targetNamespace: bls-app
EOF
```

```execute
kubectl apply -f ~/kustomization.yaml
```

---

## Step 5 — Verify the Deployment

Check Flux reconciliation status:

```execute
kubectl get kustomization -n flux-system bls-app
```

Expected: `READY=True`, `APPLIED REVISION=main/...`

Check the running pods:

```execute
kubectl get pods -n bls-app
```

Expected: `nginx-...` pod in `Running` state.

> **Checkpoint ✅** — NGINX pod is Running in `bls-app` namespace.

---

## Step 6 — View in Kommander UI

1. Open the **Kommander** tab on the right.
2. Navigate to **Clusters** → `workload01` → **Workloads**.
3. Filter by namespace `bls-app` — you will see the NGINX deployment listed.
4. Click the deployment name to see replica status, pod health, and resource usage.

---

## Step 7 — Trigger a GitOps Update

1. Edit a file in the GitLab repo — for example, change `replicas` from `1` to `2`.
2. Commit and push to `main`.
3. Within 60 seconds, Flux detects the change and reconciles.
4. Watch the pods update:

```execute
kubectl get pods -n bls-app -w
```

Press `Ctrl+C` to stop watching.

> **Observe:** A second NGINX pod starts automatically — no manual `kubectl apply` needed.

---

## Summary

You connected NKP's built-in Flux CD to a GitLab repository and deployed an application
to `workload01` entirely via GitOps. Any change pushed to GitLab is automatically applied to the cluster.
