---
title: Workshop Summary
---

## What You Built

You took a 4-service microservices application from zero to production-operated, with full
GitOps, observability, resilience, and governance — all on Nutanix Kubernetes Platform.

```mermaid
graph TB
    subgraph APP["Rx Storefront — fully operated"]
        FE["🌐 frontend"]
        CO["🛒 checkout-api"]
        CA["📋 catalog"]
        PM["💳 payment-mock v1/v2"]
        PG["🗄️ PostgreSQL<br/>on Nutanix CSI"]
        FE --> CO
        FE --> CA
        CO --> PM
        CO -.-> PG
    end

    subgraph PLATFORM["Platform Capabilities Used"]
        ARGO["🔄 ArgoCD<br/>Lab 1: GitOps deploy"]
        KIALI["🗺️ Kiali<br/>Lab 2: mesh topology"]
        JAEGER["🔍 Jaeger<br/>Lab 2: distributed tracing"]
        CANARY["🎯 Istio VirtualService<br/>Lab 3: canary rollout"]
        CSI["💾 Nutanix CSI<br/>Lab 4: block storage + snapshots"]
        PDB["🛡️ PDB + KEDA<br/>Lab 5: resilience + autoscaling"]
        GATE["🔒 Gatekeeper + RBAC<br/>Lab 6: governance"]
    end

    APP --- PLATFORM

    style APP fill:#6366f1,color:#fff
    style PLATFORM fill:#0ea5e9,color:#fff
```

---

## What You Accomplished

| Lab | What You Did |
|-----|-------------|
| **Lab 1** | Deployed a 4-service storefront via GitOps (ArgoCD + Kustomize) |
| **Lab 2** | Explored live mesh topology, traced requests through Jaeger, correlated logs by trace ID |
| **Lab 3** | Performed a canary rollout with traffic mirroring, 10/50/100% splits, and instant rollback |
| **Lab 4** | Ran PostgreSQL with Nutanix CSI block storage, took a VolumeSnapshot, restored it |
| **Lab 5** | Diagnosed latency/error incidents, drained a node with PDBs, autoscaled with KEDA |
| **Lab 6** | Enforced namespace quotas, used Gatekeeper in audit then deny mode, verified RBAC |

---

## The Core Principles — Commit These to Memory

```mermaid
graph LR
    subgraph PRINCIPLES["Six Principles of Production Kubernetes"]
        P1["📦 Git is truth\nAll state is versioned\nand auditable"]
        P2["🕸️ Observability is free\nIstio sidecars emit\nmetrics + traces"]
        P3["🎯 Limit blast radius\nMirror → canary → full\nnever big-bang"]
        P4["🔄 Declare resilience\nPDBs + anti-affinity\n= self-healing"]
        P5["💾 Storage is first-class\nCSI makes persistence\nas easy as a label"]
        P6["🛡️ Govern via platform\nOne policy protects\nall clusters at once"]
    end

    style P1 fill:#6366f1,color:#fff
    style P2 fill:#0ea5e9,color:#fff
    style P3 fill:#f59e0b,color:#fff
    style P4 fill:#10b981,color:#fff
    style P5 fill:#64748b,color:#fff
    style P6 fill:#ef4444,color:#fff
```

---

## NKP Platform Capabilities You Used

| Capability | Purpose |
|-----------|---------|
| **ArgoCD** | GitOps continuous delivery, prune on sync, self-heal |
| **Istio** | Service mesh, traffic splitting, mirroring, mTLS |
| **Kiali** | Live mesh topology visualization |
| **Jaeger** | Distributed tracing with OpenTelemetry |
| **Grafana** | Time-series metrics and dashboards |
| **Gatekeeper** | OPA-based admission control (audit → enforce) |
| **KEDA** | Event-driven autoscaling from zero |
| **Nutanix CSI** | Block (RWO) and file (RWX) dynamic provisioning |
| **VolumeSnapshots** | Point-in-time CSI snapshots and restore |

---

## Next Steps

- Explore the full NKP documentation at the NKP Console
- Try adding a second cluster to the Kommander workspace
- Experiment with building your own ArgoCD Application pointing at a custom repo
- Review the Instructor Guide for advanced demo scenarios

Thank you for participating in the NKP Hands-On Workshop!
