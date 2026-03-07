# NKP Hands-On Workshop

Welcome! In this workshop you will deploy, observe, ship, troubleshoot, and govern applications on a live Nutanix Kubernetes Platform (NKP) cluster.

## What You'll Build

The **Rx Storefront** — a 4-service microservices application:

```
Browser → frontend (nginx+React)
              │
         checkout-api (Node.js)
              ├── payment-mock v1 (Go)
              └── payment-mock v2 (Go) ← canary target
              │
         catalog (Node.js)
```

## What You'll Learn

| Lab | Topic | Key Skill |
|-----|-------|-----------|
| Lab 1 | Application Deployment | GitOps with ArgoCD |
| Lab 2 | Observability | Kiali, Jaeger, Grafana |
| Lab 3 | GitOps & Progressive Delivery | Canary rollout, rollback |
| Lab 4 | Storage & Stateful Workloads | Nutanix CSI, VolumeSnapshots |
| Lab 5 | Production Operations | Incident response, PDBs, KEDA |
| Lab 6 | Multi-Tenancy & Governance | Quotas, Gatekeeper, RBAC |

## Your Session Environment

Your session has:
- **Two terminal panes** — use them simultaneously
- **Dashboard tabs** — Storefront, ArgoCD, Kiali, Jaeger, Grafana, Demo Wall
- **Dedicated Kubernetes namespace** — you won't affect other participants

Check your session is ready:

```terminal:execute
command: kubectl get nodes
session: 1
```

```terminal:execute
command: echo "Your namespace: $SESSION_NS"
session: 1
```

When you see 3+ Ready nodes, click **Start Lab 1** below.
