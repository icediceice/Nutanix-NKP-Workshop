---
title: Contexts
---

## What We're Doing

A kubeconfig context binds together a cluster endpoint, a user identity, and a default namespace.
Operators working across multiple clusters — dev, staging, production, multiple tenants — use
contexts to switch target clusters without re-authenticating each time.

## Steps

### 1. List all contexts

```terminal:execute
command: kubectl config get-contexts
```

**Observe:** The `*` marks the active context. `CLUSTER`, `AUTHINFO`, and `NAMESPACE` show what
each context points to.

### 2. Show the full kubeconfig

```terminal:execute
command: kubectl config view
```

**Observe:** The file has three sections: `clusters`, `users`, and `contexts`. A context is just
a named pointer into the other two sections.

### 3. Switch context

```terminal:execute
command: kubectl config use-context $(kubectl config get-contexts -o name | head -1)
```

### 4. Set a default namespace on the active context

```terminal:execute
command: kubectl config set-context --current --namespace=workshop
```

**Observe:** Now every `kubectl` command in this context defaults to the `workshop` namespace
without requiring `-n workshop`.

## What Just Happened

Contexts are client-side configuration only — they live in your kubeconfig file and have no
effect on the cluster itself. Tools like `kubectx` and `kubens` wrap these same API calls to
make multi-cluster navigation faster.
