---
title: Explore Nodes
---

## What We're Doing

Nodes are the worker machines in a Kubernetes cluster — they can be physical servers or virtual
machines. Understanding node anatomy helps you reason about scheduling, capacity, and failure
domains. In this exercise you will list nodes, inspect their conditions, and read key metadata.

## Steps

### 1. List all nodes

```terminal:execute
command: kubectl get nodes -o wide
```

**Observe:** Each node shows its STATUS, ROLES, AGE, VERSION, and internal/external IP addresses.
A STATUS of `Ready` means the node is healthy and accepting workloads.

### 2. Describe a node in detail

Replace `<node-name>` with the first node shown in the previous output.

```terminal:execute
command: kubectl describe node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
```

**Observe:** Look at the `Conditions` section (MemoryPressure, DiskPressure, Ready) and the
`Allocatable` section which shows how much CPU and memory Pods can consume on this node.

### 3. Check node labels

```terminal:execute
command: kubectl get nodes --show-labels
```

**Observe:** Labels like `kubernetes.io/arch`, `node.kubernetes.io/instance-type`, and
`topology.kubernetes.io/zone` are used by the scheduler to place Pods intelligently.

## What Just Happened

You queried the Kubernetes API for Node objects and read their status conditions. The control plane
continuously reconciles these conditions — if a node goes NotReady, the scheduler stops placing
new Pods there and the node controller begins evicting existing ones.
