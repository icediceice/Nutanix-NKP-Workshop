---
title: NKP Workshop Overview
---

## What is NKP?

Nutanix Kubernetes Platform (NKP) is an enterprise Kubernetes distribution that packages everything
a production platform team needs: GitOps, observability, service mesh, storage, autoscaling, and
governance — all integrated and pre-configured on top of Kubernetes.

```mermaid
graph TB
    subgraph NKP["🏛️ Nutanix Kubernetes Platform"]
        subgraph APPS["Your Applications"]
            APP["📦 Microservices<br/>Pods / Deployments"]
        end
        subgraph PLATFORM["Platform Services (pre-installed)"]
            ARGO["🔄 ArgoCD<br/>GitOps"]
            ISTIO["🕸️ Istio<br/>Service Mesh"]
            KIALI["🗺️ Kiali<br/>Mesh Topology"]
            JAEGER["🔍 Jaeger<br/>Distributed Tracing"]
            GRAFANA["📊 Grafana<br/>Dashboards"]
            GATE["🛡️ Gatekeeper<br/>Policy Enforcement"]
            KEDA["⚡ KEDA<br/>Event-Driven Autoscaling"]
        end
        subgraph INFRA["Nutanix Infrastructure"]
            CSI["💾 Nutanix CSI<br/>Block + File Storage"]
            AHV["🖥️ AHV Nodes<br/>Worker + Control Plane"]
        end
    end

    ARGO --> APP
    ISTIO --> APP
    KIALI --> ISTIO
    JAEGER --> ISTIO
    GRAFANA --> ISTIO
    GATE --> APP
    KEDA --> APP
    APP --> CSI
    CSI --> AHV
    APP --> AHV

    style APPS fill:#6366f1,color:#fff
    style PLATFORM fill:#0ea5e9,color:#fff
    style INFRA fill:#64748b,color:#fff
```

---

## What You'll Build

The **Rx Storefront** — a 4-service microservices application that exercises every platform capability:

```mermaid
graph LR
    USER["👤 Browser"] --> FE

    subgraph APP["Rx Storefront — 4 Microservices"]
        FE["🌐 frontend<br/>nginx + React"]
        CO["🛒 checkout-api<br/>Node.js"]
        CA["📋 catalog<br/>Node.js"]
        PM1["💳 payment-mock v1<br/>Go — blue theme"]
        PM2["💳 payment-mock v2<br/>Go — green theme"]
    end

    FE --> CO
    FE --> CA
    CO --> PM1
    CO -.->|"canary traffic"| PM2

    style FE fill:#6366f1,color:#fff
    style CO fill:#0ea5e9,color:#fff
    style CA fill:#0ea5e9,color:#fff
    style PM1 fill:#10b981,color:#fff
    style PM2 fill:#f59e0b,color:#fff
```

By the end of this workshop you will have deployed this application, observed its traffic live, rolled
out v2 as a canary, backed up its database, tested resilience under node failure, and locked it down
with quota and policy governance.

---

## Workshop Map

| Lab | Topic | What You'll Do |
|-----|-------|----------------|
| **Lab 1** | Application Deployment | Deploy storefront via GitOps; see live mesh topology |
| **Lab 2** | Observability | Trace requests in Jaeger; correlate logs by trace ID |
| **Lab 3** | GitOps & Progressive Delivery | Mirror → 10% canary → 100% cutover → one-command rollback |
| **Lab 4** | Storage & Stateful Workloads | PostgreSQL + Nutanix CSI; snapshot → restore |
| **Lab 5** | Production Operations | Inject & diagnose incidents; drain a node; KEDA scale-from-zero |
| **Lab 6** | Multi-Tenancy & Governance | Quota pressure; Gatekeeper audit → deny; RBAC role separation |

---

## Your Session Environment

```mermaid
graph LR
    subgraph SESSION["Your Workshop Session"]
        T1["💻 Terminal 1<br/>primary commands"]
        T2["💻 Terminal 2<br/>watch / follow logs"]
    end
    subgraph DASHBOARDS["Dashboard Tabs"]
        SF["🛍️ Storefront"]
        ARGO["🔄 ArgoCD"]
        KIALI["🗺️ Kiali"]
        JAE["🔍 Jaeger"]
        GRAF["📊 Grafana"]
        DW["📺 Demo Wall"]
    end
    subgraph CLUSTER["Dedicated Namespace"]
        NS["📁 $SESSION_NS<br/>isolated from other participants"]
    end

    SESSION --> CLUSTER
    SESSION --> DASHBOARDS

    style SESSION fill:#6366f1,color:#fff
    style DASHBOARDS fill:#0ea5e9,color:#fff
    style CLUSTER fill:#10b981,color:#fff
```

All platform dashboards share **one login**. Log in once — your browser session covers all tabs.

---

## Platform Credentials

```bash
_NS=${SESSION_NS%-s*}
echo "Username: $(kubectl get secret dkp-workshop-credentials -n $_NS -o jsonpath='{.data.username}' | base64 -d)"
echo "Password: $(kubectl get secret dkp-workshop-credentials -n $_NS -o jsonpath='{.data.password}' | base64 -d)"
```

---

## Session Ready Check

Verify your cluster access:

```bash
kubectl get nodes
```

```bash
echo "Your namespace: $SESSION_NS"
```

**👁 Observe:** 3+ Ready nodes = you're good to go. Each node is an AHV VM managed by Nutanix.

When you see all nodes Ready, click **Start Lab 1**.
