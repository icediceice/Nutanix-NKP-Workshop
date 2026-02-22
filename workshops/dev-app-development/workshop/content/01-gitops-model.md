---
title: The GitOps Model
---

## What We're Doing

GitOps is an operational model where Git is the single source of truth for both application code
and deployment configuration. Any change to the running system must go through a Git commit.
This gives you a full audit trail, easy rollbacks (via `git revert`), and a deployment process
that any team member can understand and reproduce.

## The Two-Repository Pattern

Most GitOps implementations use two repositories:

**App repo** (`gitlab/appco/inventory-app`) — contains application source code and Dockerfile.
CI builds and pushes images when code changes.

**Config repo** (`gitlab/appco/inventory-k8s`) — contains Kubernetes manifests and Helm values.
CD watches this repo and applies changes to the cluster.

This separation means a developer pushing a code change does not directly trigger a cluster
change. The CI pipeline updates the config repo (changing the image tag in a values file), and
the CD tool picks it up from there.

## Why GitOps?

| Traditional | GitOps |
|-------------|--------|
| `kubectl apply` from laptop | Git push triggers reconciliation |
| "Who deployed that?" | Every change has a commit and author |
| Rollback = re-run old pipeline | Rollback = `git revert` |
| Cluster state can drift from scripts | Cluster state is continuously reconciled |

## What We Will Use

- **GitLab** — source control and CI runner
- **Harbor** — container image registry
- **FluxCD** — the GitOps operator running in the cluster

```terminal:execute
command: kubectl get pods -n flux-system
```

**Observe:** FluxCD components (`source-controller`, `kustomize-controller`, `helm-controller`)
are already running in the cluster, waiting for you to point them at a repository.
