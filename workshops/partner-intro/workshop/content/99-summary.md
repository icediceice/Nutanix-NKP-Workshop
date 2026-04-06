---
title: Summary and Next Steps
---

## What You Covered

```mermaid
graph TB
    subgraph M1["Module 1: Containers"]
        A1["Ran a container in < 2s"]
        A2["Saw image layers and builds"]
        A3["Watched Kubernetes self-heal"]
    end
    subgraph M2["Module 2: NKP Platform"]
        B1["Toured Kommander console"]
        B2["Explored workspace RBAC"]
        B3["Saw federated policy enforcement"]
    end
    subgraph M3["Module 3: Live Demo"]
        C1["Browsed a live ecommerce app"]
        C2["Watched Kiali service graph"]
        C3["Traced an incident in Jaeger"]
    end
    M1 --> M2 --> M3
    style M1 fill:#1A1A1A,stroke:#1FDDE9,color:#F0F0F0
    style M2 fill:#1A1A1A,stroke:#7855FA,color:#F0F0F0
    style M3 fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
```

---

## The Partner Opportunity

Your customers are running VMs on Nutanix today. The path to containers runs through the **same infrastructure** -- no rip and replace.

| Customer Need | NKP Answer |
|--------------|------------|
| "We need Kubernetes" | NKP: upstream K8s, fully supported |
| "We need multi-cluster management" | Kommander: single pane of glass |
| "We need observability" | App Catalog: Grafana, Prometheus, Kiali, Jaeger |
| "We need security and compliance" | Workspace RBAC + Kyverno policies |
| "We need to use our existing storage" | Nutanix CSI: native integration |

> **The pitch is not "replace your VMs." The pitch is: "Add NKP to what you already have, and your customers get the platform their developers are asking for -- without changing infrastructure."**

---

## Try More Yourself

Your terminal is still active. Explore:

```terminal:execute
command: kubectl get namespaces
```

```terminal:execute
command: kubectl get pods -A --no-headers | wc -l
```

```terminal:execute
command: kubectl cluster-info
```

---

## Next Steps

- **Full hands-on workshops**: Ask your facilitator about the 4-hour developer and infrastructure tracks
- **Deployment prerequisites**: vSphere/AHV requirements, sizing calculator, network planning
- **Partner resources**: Demo kits, competitive positioning, customer pitch decks
- **Lab access**: This environment stays available for the rest of the day -- keep exploring

> **Thank you for attending!** Questions? Grab your facilitator.
