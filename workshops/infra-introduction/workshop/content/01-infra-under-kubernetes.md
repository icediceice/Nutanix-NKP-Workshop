---
title: Infrastructure Under Kubernetes
---

## What We're Doing

Every Kubernetes node is a virtual machine (or bare metal server) that needs compute, storage,
and networking. On NKP, Nutanix AHV provides VMs, Nutanix Volumes provides persistent storage
via the CSI driver, and Nutanix Flow provides software-defined networking. Understanding this
stack helps you diagnose problems that originate below the Kubernetes layer.

## The Nutanix Stack

```
┌─────────────────────────────────────────┐
│           Kubernetes Workloads          │
├─────────────────────────────────────────┤
│      Kubernetes (NKP managed)           │
├──────────────────┬──────────────────────┤
│   Nutanix CSI   │   Nutanix CCM        │
│  (PV storage)   │  (LoadBalancer SVC)  │
├──────────────────┴──────────────────────┤
│         Nutanix AHV (hypervisor)        │
├────────────────────────────────────────┤
│    Nutanix AOS (distributed storage)    │
├─────────────────────────────────────────┤
│         Physical hardware nodes         │
└─────────────────────────────────────────┘
```

## Key Nutanix Components

**AHV** — Acropolis Hypervisor. An enterprise KVM-based hypervisor with built-in live migration,
HA, and the API surface that NKP calls to create worker VMs.

**AOS** — Acropolis Operating System. The distributed storage fabric. When a Pod requests a PVC,
the Nutanix CSI driver provisions a Nutanix Volume disk via AOS APIs.

**Prism Central** — The management plane for Nutanix. NKP reads cluster capacity and provisions
VMs through Prism Central APIs.

## Inspect the CSI Driver

```terminal:execute
command: kubectl get pods -n kube-system -l app=nutanix-csi-node
```

**Observe:** The CSI node driver runs as a DaemonSet — one Pod per worker node. It handles
volume attachment and detachment when Pods with PVCs are scheduled or terminated.

## What Just Happened

You have mapped the Nutanix infrastructure stack to the Kubernetes objects it supports.
Persistent storage, load balancers, and VM provisioning all flow through Nutanix APIs that NKP's
controllers invoke automatically in response to Kubernetes resource creation.
