---
title: "Workshop Overview"
---

```dashboard:create-dashboard
name: Kommander
url: https://kommander.nkp.nuth-lab.xyz
```

## Welcome to the BLS NKP Hands-On Workshop

This workshop gives you direct, hands-on experience operating **Nutanix Kubernetes Platform (NKP)**.
You will provision and manage workload clusters, deploy applications via GitOps, enable platform
services, observe infrastructure health, and run Day-2 operations — all through the NKP Kommander console.

---

## Agenda

| Lab | Topic | Duration |
|-----|-------|----------|
| Lab 1 | Workload Cluster Provisioning via NKP UI | 45 min |
| Lab 2 | Application Deployment via NKP + GitLab | 45 min |
| Lab 3 | Enable Platform Catalog | 1 hr |
| Lab 4 | Infrastructure Observability & Monitoring | 1 hr |
| Lab 5 | Production Operations (Day-2 Ops) | 1 hr |

**Total: ~4 hours 30 minutes**

---

## Your Environment

| Component | Details |
|-----------|---------|
| **Kommander (Management)** | Click the **Kommander** tab on the right → |
| **Kommander login** | `workshop@nuth-lab.xyz` / `NKP-Workshop-2026` |
| **Workload cluster** | `workload01` — your terminal is pre-wired to it |
| **kubectl** | Ready to use — try it now: |

```execute
kubectl get nodes
```

All nodes should show `Ready`. That confirms your terminal has cluster access.

---

## How These Labs Work

These are **free-hand labs**. There is no automated checker — you navigate the NKP UI and CLI at your own pace.
Each lab page describes:

1. **What** you are doing and **why** it matters
2. **Step-by-step** navigation through the Kommander UI
3. **Verification commands** — click any code block to run it in your terminal
4. **Checkpoints** to confirm you are on track before moving on

> **Tip:** Every command block in this workshop runs with a single click. Look for the ▶ button.

Your facilitator is available throughout. Raise your hand any time.
