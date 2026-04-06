---
title: "What Is NKP"
---

## Kubernetes Is Not Enough

Kubernetes solves container orchestration. But shipping Kubernetes to an enterprise customer
means answering a list of questions that Kubernetes itself does not answer:

- Which Kubernetes distribution? Maintained by whom?
- How do we install the observability stack?
- How do operators manage 20 clusters without logging into each one?
- How do developers get kubeconfigs scoped to only what they need?
- How do we enforce that no workload runs without resource limits?

Every team that "just runs Kubernetes" ends up building their own answers to these questions —
usually differently, usually without support, usually at significant cost.

---

## NKP — The Assembled Platform

NKP is Nutanix Kubernetes Platform. It is not a fork of Kubernetes. It is 100% upstream
Kubernetes — the same binaries the community ships — with an enterprise management layer built on top.

```
┌─────────────────────────────────────────────────────┐
│                  NKP Platform                        │
│                                                     │
│  Kommander (multi-cluster management)               │
│  ├── App Catalog (Istio, Kiali, Jaeger, Grafana)    │
│  ├── Workspace RBAC + Policy                        │
│  └── Cluster Lifecycle (provision, upgrade, scale)  │
│                                                     │
│  Upstream Kubernetes (unmodified)                   │
│  Nutanix CSI (storage)  │  MetalLB (load balancer)  │
└─────────────────────────────────────────────────────┘
         Running on Nutanix AHV / vSphere / Bare Metal
```

---

## How NKP Compares

| | Vanilla Kubernetes | NKP |
|-|-------------------|-----|
| Multi-cluster management | Build your own | Kommander — included |
| Observability stack | Install manually | App Catalog — one click |
| RBAC across clusters | Per-cluster configuration | Workspace policies — federated |
| Policy enforcement | Bring your own | OPA Gatekeeper — included |
| Storage | Configure CSI yourself | Nutanix CSI — native |
| Backup / DR | Bring your own | Velero — included |
| Support | Community | Nutanix enterprise support |

---

## NKP vs OpenShift

Partners often ask how NKP compares to OpenShift. Three differences stand out:

1. **Pure upstream Kubernetes** — NKP does not fork the Kubernetes API. Every kubectl command,
   every Helm chart, every operator that works upstream works on NKP unchanged.

2. **Lighter footprint** — NKP management cluster runs on fewer nodes with less overhead.
   OpenShift's operator-heavy model requires significantly more resources.

3. **Included in Nutanix, not a per-core subscription** — NKP is included with Nutanix
   infrastructure. No separate license negotiation. No per-core arithmetic.

---

## The Three Deployment Modes

NKP clusters can be provisioned three ways, depending on the customer environment:

| Mode | How it works | When to use |
|------|-------------|-------------|
| **Pre-provisioned** | Nodes already exist; NKP installs Kubernetes on them | VMware, bare metal, air-gapped |
| **CAPV** | Cluster API provisions VMs on vSphere automatically | Automated vSphere environments |
| **Bare metal** | NKP provisions directly onto physical hardware | Bare metal clusters |

All three modes are managed identically by Kommander once the cluster is running.

---

## What We Are Looking at Today

In this session, the management cluster is already running. You will see Kommander through
its two primary surfaces:

1. **kubectl** — the Kubernetes command-line tool, pointed at the management cluster
2. **NKP console** — the Kommander web UI, demonstrated by your facilitator

Let's start with the multi-tenancy model.
