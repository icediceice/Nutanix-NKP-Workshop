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

> **Your session namespace:** `bls-app-$SESSION_NAME` — all resources in this lab use this name
> so every attendee has isolated namespaces and objects on the shared cluster.

---

## Step 1 — Prepare

Get the GitLab repository URL and a **read-only personal access token** from your facilitator.

Create your isolated application namespace:

```execute
kubectl create namespace bls-app-$SESSION_NAME
```

---

## Step 2 — Create a GitLab Credentials Secret

Flux needs credentials to pull from a private GitLab repo. Set your token first (replace `YOUR_TOKEN` with the value from your facilitator):

```execute
export GITLAB_TOKEN=YOUR_TOKEN
```

Create your session-scoped secret:

```execute
kubectl create secret generic gitlab-credentials-$SESSION_NAME \
  --namespace flux-system \
  --from-literal=username=workshop-user \
  --from-literal=password=${GITLAB_TOKEN}
```

---

## Step 3 — Create a GitRepository Source

Set your GitLab URL (replace `YOUR_GITLAB_URL` with the value from your facilitator):

```execute
export GITLAB_URL=YOUR_GITLAB_URL
```

Create a `GitRepository` object pointing Flux at the repo:

```execute
cat > ~/gitrepo.yaml << EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: bls-app-source-$SESSION_NAME
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://${GITLAB_URL}/workshop/sample-app.git
  secretRef:
    name: gitlab-credentials-$SESSION_NAME
  ref:
    branch: main
EOF
```

```execute
kubectl apply -f ~/gitrepo.yaml
```

Verify Flux can reach the repo:

```execute
kubectl get gitrepository -n flux-system bls-app-source-$SESSION_NAME
```

Expected: `READY=True`, `STATUS=stored artifact for revision 'main/...'`

---

## Step 4 — Create a Kustomization

Tell Flux which path to apply to your namespace:

```execute
cat > ~/kustomization.yaml << EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: bls-app-$SESSION_NAME
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./apps/nginx
  prune: true
  sourceRef:
    kind: GitRepository
    name: bls-app-source-$SESSION_NAME
  targetNamespace: bls-app-$SESSION_NAME
EOF
```

```execute
kubectl apply -f ~/kustomization.yaml
```

---

## Step 5 — Verify the Deployment

Check Flux reconciliation status:

```execute
kubectl get kustomization -n flux-system bls-app-$SESSION_NAME
```

Expected: `READY=True`, `APPLIED REVISION=main/...`

Check the running pods:

```execute
kubectl get pods -n bls-app-$SESSION_NAME
```

Expected: `nginx-...` pod in `Running` state.

> **Checkpoint ✅** — NGINX pod is Running in `bls-app-$SESSION_NAME` namespace.

---

## Step 6 — View in Kommander UI

1. Open the **Kommander** tab on the right.
2. Navigate to **Clusters** → `workload01` → **Workloads**.
3. Filter by namespace `bls-app-$SESSION_NAME` — you will see the NGINX deployment listed.
4. Click the deployment name to see replica status, pod health, and resource usage.

---

## Step 7 — Trigger a GitOps Update

1. Edit a file in the GitLab repo — for example, change `replicas` from `1` to `2`.
2. Commit and push to `main`.
3. Within 60 seconds, Flux detects the change and reconciles.
4. Watch the pods update:

```execute
kubectl get pods -n bls-app-$SESSION_NAME -w
```

Press `Ctrl+C` to stop watching.
