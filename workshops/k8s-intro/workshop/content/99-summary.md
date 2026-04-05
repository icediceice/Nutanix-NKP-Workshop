---
title: Summary
---

## What You Built

You went from zero to a running, self-healing, network-accessible application on a real
Kubernetes cluster — understanding every layer of the stack as you went.

```mermaid
graph TB
    NS["📁 Namespace<br/>isolated environment"] --> DEP
    DEP["📋 Deployment<br/>desired state: 2 replicas"] --> RS
    RS["🔄 ReplicaSet<br/>watches & reconciles"] --> P1
    RS --> P2
    P1["📦 Pod A<br/>Container: nginx"] --> SVC
    P2["📦 Pod B<br/>Container: nginx"] --> SVC
    SVC["🔀 Service<br/>stable IP + DNS<br/>selector: app=web"]

    style NS fill:#64748b,color:#fff
    style DEP fill:#6366f1,color:#fff
    style RS fill:#0ea5e9,color:#fff
    style P1 fill:#10b981,color:#fff
    style P2 fill:#10b981,color:#fff
    style SVC fill:#f59e0b,color:#fff
```

---

## Concepts Covered

| Concept | What it does | Why it matters |
|---------|-------------|----------------|
| **Container** | Packages app + all dependencies into one image | Identical behaviour on every machine |
| **Pod** | Wraps one or more containers with shared network/storage | Smallest schedulable unit |
| **Deployment** | Declares desired replica count and image | Self-healing, rolling updates, rollback |
| **ReplicaSet** | Watches pod count, creates/deletes to match desired | The reconciliation engine |
| **Service** | Stable IP + DNS over a set of pods | Decouples consumers from pod churn |
| **Namespace** | Virtual partition of the cluster | Isolation between teams/environments |
| **Label / Selector** | Key-value metadata + query | How every object finds every other object |

---

## The Core Loop — Commit This to Memory

```mermaid
sequenceDiagram
    participant You as 👤 You
    participant API as ⚙️ API Server
    participant ETCD as 🗄️ etcd
    participant CTRL as 🔄 Controller
    participant NODE as 🖥️ Node

    You->>API: kubectl apply (desired state)
    API->>ETCD: store desired state
    CTRL->>ETCD: watch for changes
    ETCD-->>CTRL: desired ≠ actual
    CTRL->>API: create/update/delete resources
    API->>NODE: schedule pods
    NODE-->>API: pods are Running
    API->>ETCD: update actual state
```

You declare **what** you want. Kubernetes works out **how** to get there and keeps it there.

---

## What's Next

You now have the foundations. The next workshop — **NKP Platform** — builds on everything
here and shows you how real production workloads are deployed, observed, and operated on
Nutanix Kubernetes Platform.

| Next Topic | What You'll Add |
|------------|----------------|
| GitOps | Declarative deployments from Git via ArgoCD |
| Observability | Service mesh topology, distributed tracing, dashboards |
| Storage | Persistent volumes, snapshots, restore |
| Progressive delivery | Canary rollouts, traffic splitting, rollback |
