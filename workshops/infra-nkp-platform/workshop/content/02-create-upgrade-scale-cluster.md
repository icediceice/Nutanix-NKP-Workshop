---
title: Create, Upgrade, and Scale Clusters
---

## What We're Doing

Cluster lifecycle management in NKP covers three operations: creating new clusters, upgrading
the Kubernetes version on existing clusters, and scaling the worker node count. All three are
performed through CAPI objects — either via the `nkp` CLI, the Kommander UI, or direct
`kubectl` commands.

## Steps

### 1. Scale worker nodes

```terminal:execute
command: kubectl get machinedeployments -A
```

```terminal:execute
command: kubectl scale machinedeployment workshop-workers --replicas=3 -n workshop
```

```terminal:execute
command: kubectl get machines -n workshop -w
```

**Observe:** A new Machine appears in `Provisioning` state. Watch it progress to `Running`.
The corresponding VM appears in Prism Central simultaneously.

### 2. Inspect the current Kubernetes version

```terminal:execute
command: kubectl get kubeadmcontrolplane -A
```

**Observe:** The `VERSION` column shows the current Kubernetes version. Note also the
`INITIALIZED` and `API SERVER AVAILABLE` columns — these reflect control plane health.

### 3. Initiate a Kubernetes upgrade (demo)

Kubernetes upgrades in NKP follow a rolling strategy: control plane nodes are upgraded first,
then workers one at a time, ensuring zero downtime.

```terminal:execute
command: kubectl get cluster workshop-cluster -n workshop -o jsonpath='{.spec.topology.version}'
```

Your facilitator will demonstrate initiating an upgrade via:
```
nkp update cluster nutanix --cluster-name workshop-cluster --kubernetes-version v1.30.2
```

**Observe:** CAPI creates replacement Machines with the new version. Old Machines are cordoned,
drained, then deleted. The cluster remains available throughout.

## What Just Happened

All three lifecycle operations — create, scale, upgrade — are reconciled by the same CAPI
controllers. The operators declare desired state; the controllers drive to it. No SSH, no
scripts, no manual kubeadm commands.
