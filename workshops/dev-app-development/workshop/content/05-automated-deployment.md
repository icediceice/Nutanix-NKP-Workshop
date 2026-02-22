---
title: Automated Deployment with FluxCD
---

## What We're Doing

FluxCD is already running in the cluster. In this exercise you will create a `GitRepository`
source pointing at your config repo and a `Kustomization` (or `HelmRelease`) that deploys your
application. From this point forward, every commit to the config repo automatically updates
the cluster — no `kubectl apply` required.

## Steps

### 1. Create a GitRepository source

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/fluxcd/git-repository.yaml -n flux-system
```

```terminal:execute
command: kubectl get gitrepository -n flux-system
```

**Observe:** The `READY` column shows `True` when FluxCD has successfully cloned your config
repo. If it shows `False`, check the URL and the deploy key.

### 2. Create a Kustomization

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/fluxcd/kustomization.yaml -n flux-system
```

```terminal:execute
command: kubectl get kustomization -n flux-system
```

**Observe:** FluxCD applies your Kubernetes manifests from the config repo. The Deployment,
Service, and ConfigMap appear in your namespace.

### 3. Verify the application is running

```terminal:execute
command: kubectl get pods -n workshop-${SESSION_NAMESPACE}
```

```terminal:execute
command: kubectl get ingress -n workshop-${SESSION_NAMESPACE}
```

### 4. Make a code change and watch it deploy automatically

Edit a file in your `inventory-app` repo, push, wait for the CI pipeline, then watch FluxCD
pick up the config repo change:

```terminal:execute
command: kubectl get kustomization -n flux-system -w
```

**Observe:** After a successful CI run, the `REVISION` field changes to the new Git SHA and
the `READY` status momentarily shows `False` then `True` as FluxCD reconciles the new image.

## What Just Happened

You have a fully automated GitOps pipeline. Code push → CI builds image → CI updates config
repo → FluxCD detects change → cluster updated. No human steps between commit and deploy.
