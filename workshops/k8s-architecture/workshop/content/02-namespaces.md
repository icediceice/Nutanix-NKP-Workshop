---
title: Namespaces
---

## What We're Doing

Namespaces are Kubernetes's mechanism for dividing a single cluster into multiple virtual
clusters. They scope most resource types, enable resource quotas, and are the boundary for
RBAC policies. In this exercise you will create a namespace, apply a quota, and see how
resources are isolated within it.

## Steps

### 1. List existing namespaces

```terminal:execute
command: kubectl get namespaces
```

**Observe:** System namespaces (`kube-system`, `kube-public`, `kube-node-lease`) are created
by Kubernetes itself. Workshop namespaces follow the pattern `participant-NNN`.

### 2. Create a namespace

```terminal:execute
command: kubectl create namespace demo-app
```

### 3. Apply a ResourceQuota

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/namespaces/quota.yaml -n demo-app
```

```terminal:execute
command: kubectl describe resourcequota -n demo-app
```

**Observe:** The quota sets limits on total CPU, memory, and Pod count. Pods that would exceed
the quota are rejected at admission time.

### 4. See namespace-scoped vs cluster-scoped resources

```terminal:execute
command: kubectl api-resources --namespaced=true | head -20
```

```terminal:execute
command: kubectl api-resources --namespaced=false | head -10
```

**Observe:** Nodes and PersistentVolumes are cluster-scoped — they exist outside any namespace.

## What Just Happened

Namespaces give teams isolated spaces within a shared cluster. Quotas prevent one team from
consuming all cluster resources. In NKP, Workspaces build on top of namespaces to add
multi-tenancy features like role propagation and policy enforcement.
