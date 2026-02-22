---
title: Cluster API Concepts
---

## What We're Doing

Cluster API (CAPI) is a Kubernetes sub-project that applies the Kubernetes declarative model to
cluster lifecycle management. Instead of running scripts to create clusters, you create Kubernetes
custom resources — and controllers reconcile them to the desired state. NKP is built on CAPI.

## Core CAPI Objects

| Object | What it defines |
|--------|----------------|
| `Cluster` | The cluster as a whole — API server endpoint, network CIDR |
| `Machine` | A single node (VM) with desired role and version |
| `MachineDeployment` | A group of identical worker Machines (like a Deployment for nodes) |
| `KubeadmControlPlane` | The control plane Machines and their kubeadm config |
| `NutanixCluster` | Nutanix-specific infrastructure config (Prism Central, subnet, image) |
| `NutanixMachine` | Nutanix-specific VM config (vCPUs, RAM, disk, category) |

## View CAPI Objects in the Management Cluster

```terminal:execute
command: kubectl get clusters -A
```

```terminal:execute
command: kubectl get machinedeployments -A
```

**Observe:** Each managed cluster appears as a `Cluster` object. MachineDeployments control
the worker node count — scaling a MachineDeployment is how you add nodes to a cluster.

## The Reconciliation Loop

When you change a CAPI object (e.g., increase `MachineDeployment.spec.replicas`), the CAPI
controller:
1. Detects the difference between desired and actual state
2. Calls the Nutanix infrastructure provider to create a new VM
3. Bootstraps Kubernetes on the VM using kubeadm
4. Registers the node with the workload cluster
5. Updates the `Machine` object status to `Running`

```terminal:execute
command: kubectl get machines -A --sort-by='.metadata.creationTimestamp'
```

## What Just Happened

You have seen CAPI objects in the management cluster and understood how they map to physical
infrastructure. Every NKP cluster is defined entirely in CAPI custom resources — making cluster
configuration as auditable and GitOps-friendly as application configuration.
